# Migrate: Game

Game moves through the same dump pipeline as [sponsor](migrate_sponsor.md), so this runbook covers what differs and points there for the shared mechanics.

| | |
|---|---|
| Parent | [../tenant_consolidation.md](../tenant_consolidation.md), group 7 `game` |
| Status | 🔧 Preparing — tooling in place and specced; no environment has run it |

## Moved rows

Every game moves as it is, its `type` included.

| Source (every tenant schema) | Becomes (public schema) |
|---|---|
| `Game` (`IndieSpace::Game`, `NightMarket::Game`) | `Game` of the same `type` under its site |
| `thumbnail` | the original in ActiveStorage, which derives `thumb` and `large` |

| Measured in production (read-only, 2026-10-22) | Figure |
|---|---|
| tgdf2018 / tgdf | 38 / 46 `IndieSpace::Game` |
| 2022_TGDF | 130 `NightMarket::Game` |
| `site_id IS NULL` | every row — the move gives each its site |
| Thumbnails on S3 | 214 rows, 214 directories, one to one |
| Original missing | 2022_TGDF #127 — taken over from its `large` version |

The census re-takes these figures at backup, so trust the numbers it prints on the day.

## The shape

The three tasks and the files between them match sponsor's.

```
 tenant Game ── game:backup ──▶ dump.json (+ census)
                                   │
                game:migrate ◀── plan ─ preflight ─▶ refuses, nothing written
                     ├─ rows, ONE transaction ─▶ public Game
                     ├─ id_map.json ──────────▶ beside the dump
                     └─ thumbnails ───────────▶ ActiveStorage, analyzed
                game:verify ◀── plan + id_map ─▶ OK / every problem, exit 1
```

Game has no rules of its own: its plan carries each row over unchanged. The dump, the census, the thumbnail transfer and verify are the shared ones in `lib/tenant_consolidation/`; [sponsor's runbook](migrate_sponsor.md) walks each step in detail.

## Stand-in thumbnails

A thumbnail whose original is gone moves from the largest version CarrierWave cut from it.

```
 original present? ── yes ─▶ the original
        └── no ─▶ largest surviving version? ── yes ─▶ that version, listed as a stand-in
                                        └── no ──▶ preflight refuses the run
```

ActiveStorage derives every variant from whatever original it receives. The census lists each stand-in under *taken over from their largest version*. The id map records it under `stand_ins`, so the choice stays reviewable after the move. The blob keeps the name in the `thumbnail` column.

## Missing locales

Each locale moves exactly as stored, and a missing one stays missing.

| Source `name` | Public `name` | Read in `en` |
|---|---|---|
| `{ "zh-TW" => "夜市" }` | `{ "zh-TW" => "夜市" }` | 夜市, through fallback |
| `{ "en" => "…", "zh-TW" => "…" }` | unchanged | the `en` value |

The admin writes only the locale being edited, so many games never had `en`. Mobility's fallback covers it after the move as it does today. Migrate raises on a locale lost in writing. Verify compares each JSONB value whole.

## Safety net

Every layer answers a different failure.

| Layer | Catches | When |
|---|---|---|
| RDS snapshot | anything, by restoring the database | before the freeze |
| `consolidation_freeze_game` | an admin edit on the side being abandoned | backup until the switch is live |
| Census | missing files, stand-ins, leftover attachments | backup |
| Preflight | public rows present, no `Site`, no file at all | migrate, before writing |
| Write-time raises | a lost locale, a download of the wrong size | migrate |
| `game:verify` | every row, `type` and locale, thumbnail size and readability | after migrate and after the switch |

`consolidate[game]` refuses and points here, so the reviewed dump is the only way in.

## Tasks

Each task runs as a detached one-off task on ECS.

```bash
bin/rails tenant_consolidation:game:backup                 # new run in the bucket (tmp/ locally)
bin/rails "tenant_consolidation:game:migrate[<location>]"  # needs the run backup printed
bin/rails "tenant_consolidation:game:verify[<location>]"   # read-only; exits 1 on any problem
bin/rails "tenant_consolidation:rollback[game]"            # clears public Game and its thumbnails
```

Migrate analyzes every thumbnail before it exits, so nothing needs the task kept alive afterwards. Variants are made by the web service on first request.

## Runbook

The order is sponsor's: beta rehearses the operations, the production dump rehearses the data locally, then production runs.

1. Check the event calendar, the deployed tooling, and that public `games` is empty.
2. On beta, enable `consolidation_freeze_game`, then run backup, migrate and verify until `OK`.
3. Locally, take the production dump read-only as in sponsor's step 2, then run migrate, verify and rollback.
4. In production, take an RDS snapshot and record its identifier.
5. Enable `consolidation_freeze_game`.
6. Run backup and read the census; stop on anything but #127's stand-in.
7. Download the run, then run migrate and verify until `OK`.
8. Push the switch commit, deploy beta then production, and run verify again.
9. Disable `consolidation_freeze_game` and mark group 7 complete in the parent document.

## The switch commit

One commit, pushed only after production verify prints `OK`, with RSpec and Cucumber green.

| File | Change |
|---|---|
| `config/initializers/apartment.rb` | add `Game` to `excluded_models` |
| `app/models/game.rb` | plain `acts_as_tenant :site` |
| `features/step_definitions/{indie_space,night_market}/game.rb`, `spec/factories/games.rb` | attach through `thumbnail_attachment` |
| the game task specs | include `with a group before its switch` with `GameGroup` |

Apartment pins an excluded model's table to public, and STI subclasses share it. The task specs therefore put `Game` back in the tenant schemas to keep pinning the move as it ran.

## Recovery

A failed run is undone and run again whole; it never resumes. The freeze keeps the source fixed, so a fresh run reproduces the same result.

| Where it stopped | What to do |
|---|---|
| Preflight refused | fix it at the source, take a new backup |
| During the rows | run migrate again on the same run |
| During the thumbnails | `rollback[game]`, then migrate again |
| verify failed, before the switch | `rollback[game]`, fix, migrate again |
| After the switch deploy | revert the switch commit, deploy, then `rollback[game]` |
| Anything worse | restore the snapshot from step 4 |
