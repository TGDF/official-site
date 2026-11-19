# Migrate: News

News moves through the dump pipeline and the shared step sequence of the [parent document](../tenant_consolidation.md#step-sequence), so this runbook covers what is news's own.

| | |
|---|---|
| Parent | [../tenant_consolidation.md](../tenant_consolidation.md), group 9 `news` |
| Status | ⏳ Pending |

## Moved Rows

Every news item moves as it is, deleted ones included.

| Source (every tenant schema) | Becomes (public schema) |
|---|---|
| `News` | `News` under its site, same slug and status |
| `title`, `content` | the same JSONB, every locale |
| `author_type`, `author_id` | unchanged; `AdminUser` is already public |
| `thumbnail` | the original in ActiveStorage, which derives its variants |

Content keeps every `/uploads/` url it embeds. Those files stay readable, because consolidation deletes no file.

## Production Figures

The census re-takes every figure at backup; the date says when each was last measured.

| Measured read-only | Figure |
|---|---|
| Thumbnails to move | 126 (2026-08-20) |
| `/uploads/` urls in `content` | 15 (2026-08-20) |
| News without a slug | 0 in every tenant (2026-08-27) |
| `site_id IS NULL` | every row in six tenants, none in three (2026-08-27) |

Rows per site are not measured yet. The local run's backup records them here before beta starts.

## Plan Rules

The plan carries each row as it is, and refuses two cases before anything is written.

| Refused | Why |
|---|---|
| an author that is not an `AdminUser` | its id names a tenant row the move renumbers |
| two items of a site sharing a slug | they break the `(site_id, slug)` index once both carry the site's id |

A null author moves as it is. The slug check is the same one agenda runs on speakers (`Plan.slug_clashes`). News needs no preparation, since every item already has a slug.

## Safety Net

Every layer answers a different failure.

| Layer | Catches | When |
|---|---|---|
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
| 0 | Preflight | `status` shows news pending; public `news` empty |
| 1–2 | Preparation | none; skip |
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

1. Run steps 0 and 3 to 6.
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
