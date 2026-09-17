# Migrate: Sponsor (with Partner folded in)

**Parent document:** [../tenant_consolidation.md](../tenant_consolidation.md) — groups 5 `sponsor` and 6 `partner`.

**Status: 🔧 Preparing.** The tooling and this runbook are built; no data has moved. The move starts only once the preparation is confirmed, and never near the annual event (see the parent's *Timing & Sequencing*).

## What moves

| Source (every tenant schema) | Becomes (public schema) |
|---|---|
| `SponsorLevel` | `SponsorLevel`, as it is |
| `Sponsor` + `logo` | `Sponsor` under its level, logo in ActiveStorage |
| `PartnerType` | a `SponsorLevel` of the same name — or the same-site level already holding that name |
| `Partner` + `logo` | a `Sponsor` under its type's level, logo in ActiveStorage — unless a sponsor of the same site already holds its name |

| Measured in production (read-only) | Figure | As of |
|---|---|---|
| Sponsor logos in CarrierWave | 206 | 2026-08-20 |
| Sponsors with `site_id IS NULL` | 155 — the move gives every row its site | 2026-08-20 |
| Sponsors per tenant | 2018–2022: 26–33 each; 2025tgdf: 23 across 8 levels; 2026tgdf: not yet counted | 2025-12-20 |
| Partners | 48 — 2023tgdf 27 across 8 types, 2024tgdf 21 across 6 types | 2025-12-20, re-confirmed 2026-08-20 |
| SponsorLevels / Sponsors in 2023tgdf and 2024tgdf | 0 — no level reuse and no skipped partner expected | 2025-12-20 |
| Embedded `/uploads/` in `Sponsor.description` | 0 | 2026-08-20 |

Partner is retired: it is never consolidated as Partner rows. Its tenant rows stay where they are, and its code goes in Phase 5. The figures come from the parent's *Measured state*; the census re-takes them at backup time, so the numbers to trust on the day are the ones the backup prints.

## The shape

```
 tenant schemas (9)                          S3 (private)  s3://<bucket>/consolidation/sponsor/<time>/
 ──────────────────                          ────────────────────────────────────────────────────────
 SponsorLevel Sponsor ─┐
 PartnerType  Partner ─┴─ sponsor:backup ───▶ dump.json ───────────────┐      ──▶ aws s3 cp … ./  (keep)
                          (+ census)                                   │
                                                                       ▼
                                   sponsor:migrate ◀── Transform(dump) ─ preflight ─▶ refuses, nothing written
                                         │
                                         ├─ rows, all sites, ONE transaction ─▶ public SponsorLevel / Sponsor
                                         ├─ id_map.json (old id → new id) ────▶ S3, beside the dump
                                         └─ logos, one transaction each ──────▶ ActiveStorage, analyzed
                                                                       │
                                   sponsor:verify ◀── Transform(dump) + id_map ─▶ OK / every problem, exit 1
```

The move is three tasks around one reviewed file, and each can be run, read and repeated on its own. Backup reads the tenant schemas into a dump. Migrate writes that dump into the public schema and records where every row went. Verify reads the public schema back against the dump through that record. The sections below follow the same order, from the file each task reads down to the checks it makes on a single logo.

## Backup: the dump and the census

| The dump holds, per site | Used by |
|---|---|
| every column of every row, nil included, timestamps to the microsecond | migrate writes it back; verify compares against it |
| each logo's `url`, `path` and `size` as fog reports it on S3 | migrate downloads it; the size is the integrity baseline |
| each CarrierWave version of that logo (`v1`), with its own `url`, `path` and `size` | nothing — kept as the record of what was served before the move |
| row counts per site, written after the rows | parse refuses a dump that lost rows |

The dump is the reviewed input: migrate imports exactly it, and a re-run imports the same file again. It holds no file bytes — the originals and their versions stay in `uploads/` on S3 until Phase 5.5. Versions are not moved, because ActiveStorage makes its own variants. Before anything is written, the census prints the counts, logos whose source is missing, leftover attachments on Sponsor ids, partners that will be skipped and labels that will change.

## Migrate: how rows are planned

```
 SponsorLevel ────────────────────────────────────────▶ level
 PartnerType ── a same-site level has that name? ── yes ─▶ (reuses it)
                                                └── no ──▶ level; 2023tgdf label corrected
 Sponsor ─────────────────────────────────────────────▶ sponsor under its level
 Partner ─── its name already taken in the site? ── yes ─▶ skipped, listed for review
                                                 └── no ──▶ sponsor under its type's level
```

| English label | 2023tgdf holds | Becomes |
|---|---|---|
| Supporting Partners | 協辦單位 | 合作單位 |
| Co-organizers | 合作單位 | 協辦單位 |

`Transform` is the single statement of what each site becomes: the census prints it, migrate writes it, and verify compares public against it. Names compare as the whole JSONB value, every locale at once. 2023tgdf's PartnerType labels pair English and Chinese the other way round from every other year, so the transform gives them the labels every other year uses. The rules are pinned by specs with literal outcomes (`sponsor_migrate_spec.rb`, `sponsor_journey_spec.rb`).

## Migrate: how a logo moves

```
 dump: url, size, logo column ("創投標誌.png")
   │
   ├─ download the url ─────────────────────── fails ─▶ raise; rows stay, logo missing
   ├─ upload a blob named by the logo column
   ├─ size ≠ dump size (empty, CDN error page) ─ yes ──▶ raise
   ├─ analyze with vips ─────────────────────── unreadable ─▶ analyzed, no width/height
   └─ attach, save without validation ─────────────────▶ committed; no job enqueued
        any raise after the upload purges the blob first
```

Each logo moves in its own transaction after the rows commit. The blob takes the name stored in the logo column, not the URL's, because a URL percent-encodes a name that is not ASCII. It is analyzed before it is attached, inside the task: analysis left to an `AnalyzeJob` would run on the in-process adapter and die with the one-off task. So when migrate exits, every logo is analyzed. An image vips cannot read does not stop the run — verify names it, so a single run lists every such logo at once.

## Verify: what it checks

| Checked | Reported as |
|---|---|
| every planned row has a public row, in the right site and level | `has no public …`, `belongs to site …`, `is under level …` |
| every column and locale matches the dump | `.<column> is …, expected …` |
| no public row the plan does not account for | `public holds N … row(s), the plan has M` |
| a logo is attached, named and sized as the dump says | `has no logo …`, `logo is <name>, expected …`, `logo is N bytes …` |
| the logo was analyzed | `logo was never analyzed` |
| vips could read it: analysis found a width and height | `logo cannot be read as an image` |

Verify only reads, so it can run as often as wanted — before the switch deploy and after it. It replans each site with the same `Transform` the import used and finds each public row through the id map, so it checks every row rather than a count. `updated_at` is skipped on a sponsor that carried a logo, since attaching touches the record. A readable logo is readable to vips here, which is what serves its variant once the switch is live.

## The safety net

| Layer | Catches | When |
|---|---|---|
| RDS snapshot | anything, by restoring the database | before the freeze |
| Write freeze (`consolidation_freeze_sponsor`, `_partner`) | an admin edit landing on the side about to be abandoned | from backup until the switch deploy is live |
| Dump in S3, downloaded | the reviewed input, kept outside the database | backup |
| Census | missing logo files, leftover attachments, skipped partners, changed labels | backup, before anything is written |
| Preflight refusal | Sponsor already public, public rows present, a tenant with no `Site`, an unresolvable foreign key, a missing logo, a leftover attachment | migrate, before anything is written |
| One transaction for all rows | a half-moved site | migrate |
| Write-time raises | a lost locale; a logo whose download differs in size from the source | migrate |
| `sponsor:verify` | the checks above, unreadable logos included | after migrate, and again after the switch |
| Specs, CI with libvips | each promise above, proven by breaking it on purpose | CI |

Every layer answers a different failure, and none relies on the one after it. Two things are outside the net by design. The dump is not a restore path — the snapshot is. And the logo bytes are not in the dump: the originals stay in `uploads/` on S3, untouched by the move, and are only deleted in Phase 5.5 behind its own gate.

## Tasks

```bash
bin/rails tenant_consolidation:sponsor:backup                 # new run in the bucket (tmp/ locally)
bin/rails "tenant_consolidation:sponsor:backup[<location>]"   # or a location of your choosing
bin/rails "tenant_consolidation:sponsor:migrate[<location>]"  # needs the run backup printed
bin/rails "tenant_consolidation:sponsor:verify[<location>]"   # read-only; exits 1 on any problem
bin/rails "tenant_consolidation:rollback[sponsor]"            # clears public SponsorLevel/Sponsor
```

A location is a local directory or `s3://<application bucket>/consolidation/…`; anything else is refused, and `consolidate[sponsor]` and `consolidate[partner]` stop and point here. On ECS, run each as a **detached one-off task** so a dropped shell cannot cut a run short. The container's entrypoint is `bin/openbox`, which runs `rake <task>`, and the output lands in the task's CloudWatch log stream. The task needs nothing kept alive after it exits: migrate analyzes every logo before it ends.

## Runbook

```
            beta (own data)          local (production dump)        production
            ───────────────          ───────────────────────        ──────────
 rehearse   freeze → backup →        read-only backup(prod) → log → ·
            migrate → verify         migrate → verify → rollback
 run        ·                        ·                              snapshot → freeze → backup →
                                                                    download → migrate → verify
 switch     auto-deploys first  ◀─── push the switch commit ───▶    waits for approval
            check it                                                approve → check → verify → unfreeze sponsor
```

Beta has little data, so it rehearses the **operations**: the freeze, the tasks on ECS, the deploy order. The **data** is rehearsed locally, against the production dump, where the logos are real and libvips analyzes every one of them. Production runs only after both rehearsals print `OK`, and the switch commit is pushed only after production does. Beta then deploys first and serves as the canary for the approval-gated production deploy.

### 0. Before starting

| Check | Why |
|---|---|
| Not near the annual event | the freeze stops sponsor edits in the admin |
| This tooling is deployed to the environment | the tasks must exist there |
| `tenant_consolidation:status` shows sponsor pending; public `sponsor_levels` / `sponsors` are empty | migrate refuses public rows already present |
| No ActiveStorage attachment sits on a `Sponsor` id | it would land on whichever new sponsor takes that id |

The census and the preflight both report a leftover attachment, so the last check is also enforced by the tasks. `cleanup_attachments` purges those whose id matches a tenant row; one that matches no row has to be removed by hand. Every other check is a judgement the tasks cannot make, which is why it is written here rather than coded. Settle all four before touching beta.

### 1. Beta — rehearse the operations

| Step | Action | Must see |
|---|---|---|
| 1 | Enable `consolidation_freeze_sponsor` and `consolidation_freeze_partner` in beta's `/flipper` | admin sponsor and partner edits refused |
| 2 | `sponsor:backup` | the census |
| 3 | `sponsor:migrate[<location>]`, then `sponsor:verify[<location>]` | `OK` |
| 4 | Leave beta migrated and frozen | — |

Beta stays migrated because the switch commit deploys to beta first and needs its data already in public. If the production run is postponed, run `rollback[sponsor]` on beta and lift the freeze, so beta's admin is not left frozen with nothing to show for it. What beta proves is the sequence on ECS, not the data: its few sponsors cannot surface a production logo that vips cannot read.

### 2. Local — rehearse the data with the production dump

```
 laptop ── AWS_PROFILE=tgdf ──▶ one-off prod task: backup[/tmp/run]   reads the database, HEADs S3
                                   │  dump stays in the container; printed as numbered base64 lines
                                   ▼
                              CloudWatch log stream ecs/web/<task-id>
                                   │  filter DUMP lines, sort by number, decode, check SHA256
                                   ▼
 laptop: ./<time>/dump.json ─▶ Sites ─▶ migrate ─▶ verify ─▶ rollback
```

The rehearsal writes nothing to production. The backup is given a directory inside the task's own container, so no dump reaches S3, and the task only reads the database and asks S3 for file sizes. The dump leaves the container through its log, gzipped, base64-encoded and numbered line by line, because a one-off task's disk is gone when it stops. The production image must already carry the tooling this runbook describes, since a dump from older tooling lacks fields the local parser requires.

#### 2a. Take the dump through the task log

```bash
cd ~/Workspace/TGDF
AWS_PROFILE=tgdf ./ecs-console.sh prod run "'tenant_consolidation:sponsor:backup[/tmp/run]' && echo SHA256 \$(sha256sum /tmp/run/dump.json | cut -d' ' -f1) && gzip -c /tmp/run/dump.json | base64 | tr -d '[:space:]' | fold -w 76 | awk -v p=DUMP '{print p, NR, \$0}'"
# note the task id it prints; the census is at the head of the log it shows

GROUP=$(AWS_PROFILE=tgdf aws ecs describe-task-definition --task-definition "$(AWS_PROFILE=tgdf aws ecs describe-services \
  --cluster official-website-prod --services web --query 'services[0].taskDefinition' --output text)" \
  --query 'taskDefinition.containerDefinitions[0].logConfiguration.options."awslogs-group"' --output text)
AWS_PROFILE=tgdf aws logs filter-log-events --log-group-name "$GROUP" --log-stream-names "ecs/web/<task-id>" \
  --output json | jq -r '.events[].message' > <time>.log   # the CLI follows every page
mkdir <time> && grep '^DUMP ' <time>.log | sort -k2,2n | cut -d' ' -f3 | tr -d '\n' | base64 -d | gunzip > <time>/dump.json
shasum -a 256 <time>/dump.json; grep '^SHA256 ' <time>.log   # the two digests must match
```

| Must see | If not |
|---|---|
| the task exits 0 and the log opens with the census | read the census; stop on anything the production run would stop on |
| the two SHA256 digests match | the log was cut or reordered badly — take the dump again |

The numbering is what makes the log safe to read back: events that share a timestamp can come back out of order, and sorting by number restores them. The digest is taken inside the container before encoding, so a match proves the local file is byte for byte the dump the task wrote.

#### 2b. Move, check and undo locally

```bash
bin/rails runner '
  JSON.parse(File.read("<time>/dump.json"))["sites"].each do |s|
    Site.find_or_create_by!(tenant_name: s["tenant_name"]) do |site|
      site.name = s["tenant_name"]
      site.domain = "#{s["tenant_name"].downcase.tr("_", "-")}.localhost.test"
    end
  end'
bin/rails "tenant_consolidation:sponsor:migrate[<time>]"   # logos download from the public production CDN
bin/rails "tenant_consolidation:sponsor:verify[<time>]"    # must print OK
bin/rails "tenant_consolidation:rollback[sponsor]"
```

This is the only rehearsal that meets every production logo, so it is where an unreadable image shows up first. Migrate refuses a tenant with no `Site`, hence the runner. Local development needs libvips, as the project setup already requires. A logo verify names as unreadable is a source problem, not a tooling one: fix or replace it at the source, take a new dump, and rehearse again. Downloading logos reads the public CDN only.

### 3. Production — the run

| Step | Action | Stop when |
|---|---|---|
| 1 | RDS snapshot, one exact identifier recorded (the parent's *Create RDS Snapshot*) | — |
| 2 | Enable `consolidation_freeze_sponsor` and `consolidation_freeze_partner` | — |
| 3 | `sponsor:backup`, read the census | a missing logo, a leftover attachment, or a count or skipped partner you did not expect |
| 4 | Download the run (`aws s3 cp s3://<bucket>/consolidation/sponsor/<time> ./<time> --recursive --profile tgdf`) and keep it | — |
| 5 | `sponsor:migrate[<location>]`, then `sponsor:verify[<location>]` | anything but `OK` |

From step 2 until the switch deploy is live, an admin edit to either group would be lost, so the window should be as short as the approval allows. Migrate needs no further waiting once it exits, because every logo is analyzed inside it. Verify must print `OK` before the switch commit is pushed; a problem here is recovered by the *Recovery* table while nothing public reads these rows yet.

### 4. The switch commit

| File | Change |
|---|---|
| `config/initializers/apartment.rb` | add `SponsorLevel` and `Sponsor` to `excluded_models` — never `Partner` / `PartnerType` |
| `app/models/sponsor.rb`, `app/models/sponsor_level.rb` | plain `acts_as_tenant :site` (drop `optional:` and `has_global_records:`) |
| `app/controllers/pages_controller.rb` | `@partners_and_sponsors` from Sponsor only |
| `app/views/pages/index.html.erb` | render the block on `Sponsor.exists?` |
| `app/controllers/sponsors_controller.rb`, `app/views/sponsors/index.html.erb` | drop `@partner_types` |
| `features/admin/admin_sponsors.feature` | the attached field is `logo_attachment` |
| `features/step_definitions/sponsor.rb`, `spec/factories/sponsors.rb` | attach the logo through `logo_attachment` |

It is one commit, pushed only after step 3 prints `OK`, with RSpec and Cucumber green. Every partner is now a sponsor, so the public pages stop reading Partner or each would show twice. The tests follow ActiveStorage so they exercise the path production now takes rather than the CarrierWave fallback. The Partner admin screens stay, behind `consolidation_freeze_partner`, until Phase 5 removes Partner.

### 5. Deploy and close the window

```
 freeze ─┬─ backup ── migrate ── verify ── switch commit ── deploy (beta → prod) ─┬─ unfreeze sponsor
         │                                                                        │
         └────────── an admin write here lands in the tenant schema and is lost ──┘
```

Push, and check beta's sponsor pages and admin form once it deploys. Approve the production deploy, then check the sponsor pages, the admin form (the upload field is `logo_attachment`) and that logo URLs are ActiveStorage ones; the first request for each logo makes its variant, which the CDN then caches. Run `sponsor:verify[<location>]` again — it must still print `OK`. Disable `consolidation_freeze_sponsor`, leave `consolidation_freeze_partner` on, and mark groups 5 and 6 complete in the parent document.

## Recovery

| Where it stopped | State | What to do |
|---|---|---|
| Preflight refused | nothing written | fix what it named at the source, take a new backup |
| During the rows | nothing written — one transaction | fix the cause, run migrate again on the same run |
| During the logos | rows and id map in public, some logos missing | `rollback[sponsor]`, then migrate again on the same run |
| verify failed, before the switch | rows in public, not served | `rollback[sponsor]`, fix, migrate again |
| After the switch deploy | public rows are live | revert the switch commit and deploy it, then `rollback[sponsor]` |
| Anything worse | — | restore the snapshot recorded in step 3.1 (the parent's *Rollback Strategy*, Level 3) |

`rollback[sponsor]` refuses while `Sponsor` is in `excluded_models`, and deletes every public `SponsorLevel` and `Sponsor` — the merged partners and their logos included — which is what makes a clean re-run possible before the switch. A logo that failed mid-move leaves no blob behind, since migrate purges it before raising. The tenant rows are never touched by any of this.
