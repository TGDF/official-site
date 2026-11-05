#!/usr/bin/env bash
# Keeps the AWS managed prefix lists that gate the load balancer's ingress equal to
# Cloudflare's published edge ranges, so only Cloudflare can reach the origin and a
# range Cloudflare adds is let in without anyone watching for it.
#
# Usage: sync-cloudflare-ips.sh <ipv4-prefix-list-id> <ipv6-prefix-list-id>
# DRY_RUN=1 reports the difference without modifying anything.
set -euo pipefail

PL_V4=${1:?ipv4 prefix list id}
PL_V6=${2:?ipv6 prefix list id}
DRY_RUN=${DRY_RUN:-0}

# A malformed or truncated answer must never shrink the allowlist: an emptied list
# would cut every visitor off. Cloudflare publishes 15 IPv4 and 7 IPv6 ranges.
MIN_V4=10
MIN_V6=5

ips=$(curl -fsS --retry 3 https://api.cloudflare.com/client/v4/ips)
if [ "$(jq -r '.success' <<<"$ips")" != "true" ]; then
  echo "::error::Cloudflare IP API did not report success"
  exit 1
fi

sync_list() {
  local list_id=$1 key=$2 minimum=$3
  local wanted current add remove max version

  wanted=$(jq -r ".result.${key}[]" <<<"$ips" | sort -u)
  if [ "$(grep -c . <<<"$wanted")" -lt "$minimum" ]; then
    echo "::error::Cloudflare returned fewer than ${minimum} ${key}; refusing to sync"
    exit 1
  fi

  current=$(aws ec2 get-managed-prefix-list-entries --prefix-list-id "$list_id" \
    --query 'Entries[].Cidr' --output text | tr '\t' '\n' | grep . | sort -u || true)
  add=$(comm -23 <(echo "$wanted") <(echo "$current"))
  remove=$(comm -13 <(echo "$wanted") <(echo "$current"))

  if [ -z "$add" ] && [ -z "$remove" ]; then
    echo "${list_id} (${key}): in sync, $(grep -c . <<<"$wanted") entries"
    return
  fi

  echo "${list_id} (${key}): add [$(paste -sd" " <<<"$add")] remove [$(paste -sd" " <<<"$remove")]"
  read -r max version < <(aws ec2 describe-managed-prefix-lists --prefix-list-ids "$list_id" \
    --query 'PrefixLists[0].[MaxEntries,Version]' --output text)
  if [ "$(grep -c . <<<"$wanted")" -gt "$max" ]; then
    echo "::error::${list_id} holds at most ${max} entries; raise MaxEntries first"
    exit 1
  fi
  [ "$DRY_RUN" = "1" ] && return

  local args=(--prefix-list-id "$list_id" --current-version "$version")
  [ -n "$add" ] && args+=(--add-entries "$(jq -Rnc '[inputs | {Cidr: ., Description: "cloudflare"}]' <<<"$add")")
  [ -n "$remove" ] && args+=(--remove-entries "$(jq -Rnc '[inputs | {Cidr: .}]' <<<"$remove")")
  aws ec2 modify-managed-prefix-list "${args[@]}" --query 'PrefixList.State' --output text
  echo "::notice::${list_id} (${key}) updated: add [$(paste -sd" " <<<"$add")] remove [$(paste -sd" " <<<"$remove")]"
}

sync_list "$PL_V4" ipv4_cidrs "$MIN_V4"
sync_list "$PL_V6" ipv6_cidrs "$MIN_V6"
