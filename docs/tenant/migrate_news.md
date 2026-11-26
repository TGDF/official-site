# Migrate: News

News moves through the dump pipeline and the shared step sequence of the [parent document](../tenant_consolidation.md#step-sequence), so this runbook covers what is news's own.

| | |
|---|---|
| Parent | [../tenant_consolidation.md](../tenant_consolidation.md), group 9 `news` |
| Status | ✅ Complete (2026-11-26) — local, beta and production each ran the step sequence; production moved 126 news and thumbnails, and `news:verify` printed `OK` before and after the switch. The runbook is kept as the record of how the move ran. |

## Moved Rows

Every news item moves as it is, deleted ones included.

| Source (every tenant schema) | Becomes (public schema) |
|---|---|
| `News` | `News` under its site, same slug and status |
| `title`, `content` | the same JSONB, every locale |
| `author_type`, `author_id` | unchanged; `AdminUser` is already public |
| `thumbnail` | the original in ActiveStorage, which derives its variants |

Content keeps every `/uploads/` url it embeds, and each resolves after the move as it did before, because consolidation deletes no file.

## Production Figures

Local and production backups must print these figures; the census re-takes them on the day.

| Measured read-only, 2026-11-19 | Figure |
|---|---|
| Sites / news | 9 / 126 |
| Per site | tgdf2018 11, tgdf 14, tgdf_2020 9, tgdf_2021 16 |
| | 2022_TGDF 18, 2023tgdf 18, 2024tgdf 16, 2025tgdf 18, 2026tgdf 6 |
| Status | 115 published, 2 draft, 9 deleted |
| Authors | 126 `AdminUser` |
| Thumbnails | 126; stand-ins tgdf_2020 News#2, #4 ← `large` |
| `site_id IS NULL` | every row in the six tenants up to 2023tgdf |

## Embedded Urls

The content embeds 18 `/uploads/` urls, 15 distinct, and the move carried each unchanged. Eight named `https://tgdf.tw`, the host CarrierWave wrote while uploads were still served from the app's own disk, before they moved to S3 in March 2022. That host no longer serves `uploads/`, so they had 404'd since; their files resolve under `files.tgdf.tw`.

| Host in the url | Count | Now |
|---|---|---|
| `https://files.tgdf.tw` | 10 | resolves, as before |
| `https://tgdf.tw` → `https://files.tgdf.tw` | 8 | resolves since 2026-11-26 |

The eight sit in tgdf_2021 News #1 to #5, #7 and #12. Their host was corrected in production after the switch and before the unfreeze, as a content edit separate from the move: one `replace` over the JSONB, every locale, `updated_at` untouched. `news:verify` against the run's dump therefore reports those seven items' content. A link to `https://tgdf.tw/` itself, in 2023tgdf News #18, is not an upload and stays.

## Plan Rules

The plan carries each row as it is, and refuses two cases before anything is written.

| Refused | Why |
|---|---|
| an author that is not an `AdminUser` | its id names a tenant row the move renumbers |
| two items of a site sharing a slug | they break the `(site_id, slug)` index once both carry the site's id |

A null author moves as it is. The slug check is the same one agenda runs on speakers (`Plan.slug_clashes`). Every item already has a slug, so the one preparation news needs is clearing public's own rows, below.

## Main-site Rows

Public's own `news` table was not empty: it held rows from the retired main site, which preflight refuses (`public news already holds N row(s)`). Each is a test post, or an item posted to the main site by mistake and posted again to its year's site minutes later, so no content lives only there.

| Environment | Rows | What they are |
|---|---|---|
| Beta | 4 | test posts |
| Production | 6 | duplicates of tgdf2018 #1, #3; tgdf_2021 #1; 2024tgdf #6, #8, #13 |

They go at step 2, after step 1's restore point: each row exported in full, then a guarded `delete_all` (exact count, every `site_id` null). Not `rollback[news]`: its `destroy!` lets CarrierWave remove their thumbnails under `uploads/public/`, and `uploads/` stays.

## Safety Net

Every layer answers a different failure.

| Layer | Catches | When |
|---|---|---|
| Restore point, step 1 | the main-site rows cleared at step 2 | before the freeze |
| Restore point, step 4 | anything in the move | after the freeze |
| `consolidation_freeze_news` | admin edits on the old side | step 3 to step 9 |
| Census | missing files, stand-ins, leftover attachments | backup |
| Plan | a foreign author, a shared slug | backup, migrate |
| Write-time check | a column a save rewrote, a slug included | migrate |
| `news:verify` | every row, locale, author, thumbnail | steps 6 to 8 |

`consolidate[news]` refuses and points here.

## Tasks

Beta and production run each task as a detached one-off task on ECS; the local run uses the same commands.

```bash
bin/rails "tenant_consolidation:news:restore[<directory>]"   # local run only
bin/rails tenant_consolidation:news:backup
bin/rails "tenant_consolidation:news:migrate[<location>]"
bin/rails "tenant_consolidation:news:verify[<location>]"     # read-only; exits 1 on any problem
bin/rails "tenant_consolidation:rollback[news]"
```

## News Steps

Each environment runs the parent's step sequence; this table names what news checks at each step.

| # | Step | Must see for news |
|---|---|---|
| 0 | Preflight | `status` shows news pending; public `news` holds only main-site rows |
| 1–2 | Preparation | main-site rows exported, then public `news` empty |
| 3 | Freeze | `consolidation_freeze_news` on |
| 4 | Restore point | identifier recorded |
| 5 | Backup | census matches the figures above |
| 6 | Migrate, then verify | `OK` |
| 7 | Rollback, migrate, verify | public `news` empty, then `OK` |
| 8 | Switch | news list and pages serve; `OK` |
| 9 | Unfreeze and record | run noted in this runbook |

Beta checks step 5 against its own census, recorded on its run, since its data is not production's.

## Local Run

The local run rebuilds production's tenant rows first, as the parent's [Local Data](../tenant_consolidation.md#local-data) describes.

1. In production, run `news:backup` into the task's own disk.
2. Bring the dump home through the task log, and compare its SHA256.
3. Run `news:restore` on that directory.
4. Run steps 0 to 9 with production's `ASSETS_HOST`, taking a `pg_dump` of the local database as each restore point.

Step 8 applies the switch commit locally and runs RSpec, Cucumber and the pages.

## Beta Run

Beta runs steps 0 to 9 on its own data, with an RDS snapshot as each restore point.

1. Run steps 0 to 7.
2. Push the switch commit, as step 8.
3. Wait for beta's deploy, then run verify again.
4. Run step 9.

From the push on, approve no production deploy until production's step 6 prints `OK` ([Switch Timing](../tenant_consolidation.md#switch-timing)). Hold every other merge through that window.

## Production Run

Production runs steps 0 to 9 except step 7, with an RDS snapshot as each restore point.

1. Run steps 0 to 6.
2. Approve the production deploy that carries the switch, as step 8.
3. Run verify again once the deploy is live.
4. Run step 9, then mark group 9 complete in the parent document.

## Switch Commit

One commit, written in the local run's step 8 with RSpec and Cucumber green.

| File | Change |
|---|---|
| `config/initializers/apartment.rb` | add `News` to `excluded_models` |
| `app/models/news.rb` | plain `acts_as_tenant :site`; restate the slug validation's comment |
| news factory, features, admin specs | attach through `thumbnail_attachment` |

The news task specs already include `with a group before its switch`, so they keep pinning the move as it ran.

## Recovery

A failed run is undone and run again whole; it never resumes.

| Where it stopped | What to do |
|---|---|
| Plan or preflight refused | fix it at the source, take a new backup |
| During the rows | run migrate again on the same run |
| During the thumbnails | `rollback[news]`, then migrate again |
| verify failed, before the switch | `rollback[news]`, fix, migrate again |
| After the switch deploy | revert the switch commit, deploy, then `rollback[news]` |
| Anything worse | restore step 4's restore point |
