# Migrate: Agenda

Agenda moves through the dump pipeline and the shared step sequence of the [parent document](../tenant_consolidation.md#step-sequence), so this runbook covers what is agenda's own.

| | |
|---|---|
| Parent | [../tenant_consolidation.md](../tenant_consolidation.md), group 8 `agenda` |
| Status | ✅ Complete (2026-11-12) — local, beta and production each ran steps 0 to 9; production moved 2,075 rows into 23 shared tags and 371 avatars, and `agenda:verify` printed `OK` before and after the switch. The runbook is kept as the record of how the move ran. |

## Moved Rows

The eight tables move together, because each points at another.

```
 AgendaDay <--day_id-- AgendaTime <--time_id--+
                             Room <--room_id-- Agenda <--agenda_id-- AgendasSpeaker --speaker_id--> Speaker
 AgendaTag <--agenda_tag_id-- AgendasTagging --agenda_id--> Agenda
```

Every foreign key is rewritten to its own site's new parent through the plan's refs (`AgendaGroup::REFS`). Speaker's `avatar` moves into ActiveStorage. A null `time_id` or `room_id` stays null.

## Production Figures

Local and production backups must print these figures; the census re-takes them on the day.

| Measured read-only | Figure |
|---|---|
| Sites | 9 |
| Days / times / rooms | 24 / 179 / 28 |
| Agendas / speakers | 406 / 371 |
| Speaker links / taggings | 412 / 562 |
| Tags | 93, merged into 23 shared |
| Taggings left out | 20, all in tgdf_2020 |
| Avatar stand-in | tgdf_2020 Speaker#8 ← `v1_large` |
| Speakers without a slug | 175, every one `#id → id` |

The rows were measured on 2026-10-29. The slug figure is the 2026-11-12 dry run: tgdf2018 41, tgdf 53, tgdf_2020 38, tgdf_2021 43.

## Shared Tags

Tags are one vocabulary across every year. Each distinct tag becomes a single `AgendaTag` that belongs to no site.

| Source | Public |
|---|---|
| a tag per site, same `name` | one tag, `site_id` null |
| its timestamps | the first site's copy |
| every tagging | points at the shared tag |

Tags match on their whole `name`, every locale included. Production's 93 tags give exactly 23 names, with no name differing in one locale only. The census lists each shared tag with the tags it stands for. Tags stay under each year's agenda menu in the admin, where an edit now changes every year.

## Left-out Taggings

A tagging whose tag or agenda is gone is left out, listed in the census and kept in the id map's `skipped`.

| tgdf_2020 | Detail |
|---|---|
| Taggings | 20, to AgendaTag #2 or #5 |
| Their agendas | all present |
| Cause | `287ea625`, 2020-06-20 |

Before that commit, deleting a tagging also deleted its tag. Removing agendas #28 and #38 on 2020-06-17 took tags #2 and #5 with them. The other agendas' taggings were left pointing at nothing, since the table has no database foreign key. Pages already hide them.

## Slug Preparation

Agenda's preparation, step 2 of the sequence, gives every speaker a slug so its `/speakers/<id>` link survives the new ids.

| Stage | Guard |
|---|---|
| `backfill_speaker_slugs` | writes each missing slug as the speaker's current id |
| backup | refuses a slugless speaker, or two of a site sharing a slug |
| migrate | aborts on a save that rewrote any column |

The backfill leaves every page as it was, since FriendlyId already fell back to the id. An id another speaker uses as a slug gets a `-2` suffix. The ids it prints are its undo record, and its slugs stay through any rollback.

## Safety Net

Every layer answers a different failure.

| Layer | Catches | When |
|---|---|---|
| Restore point, step 1 | a bad slug backfill | before step 2 |
| Restore point, step 4 | anything in the move | after the freeze |
| `consolidation_freeze_agenda` | admin edits on the old side | step 3 to step 9 |
| Census | missing files, stand-ins, left-out taggings, shared tags | backup |
| Plan | a slugless speaker, a shared slug, an unmapped key | backup, migrate |
| Write-time check | a column a save rewrote | migrate |
| `agenda:verify` | every row, ref, locale, avatar, shared tag | steps 6 to 8 |

`consolidate[agenda]` refuses and points here.

## Tasks

Beta and production run each task as a detached one-off task on ECS; the local run uses the same commands.

```bash
bin/rails "tenant_consolidation:agenda:restore[<directory>]"   # local run only
bin/rails "tenant_consolidation:backfill_speaker_slugs[true]"  # dry run
bin/rails tenant_consolidation:backfill_speaker_slugs
bin/rails tenant_consolidation:agenda:backup
bin/rails "tenant_consolidation:agenda:migrate[<location>]"
bin/rails "tenant_consolidation:agenda:verify[<location>]"     # read-only; exits 1 on any problem
bin/rails "tenant_consolidation:rollback[agenda]"
```

## Agenda Steps

Each environment runs the parent's step sequence; this table names what agenda checks at each step.

| # | Step | Must see for agenda |
|---|---|---|
| 0 | Preflight | `status` shows agenda pending; eight public tables empty |
| 1 | Restore point | identifier recorded |
| 2 | Slug preparation | dry run list equals the apply list |
| 3 | Freeze | `consolidation_freeze_agenda` on |
| 4 | Restore point | identifier recorded |
| 5 | Backup | census matches the figures above |
| 6 | Migrate, then verify | `OK` |
| 7 | Rollback, migrate, verify | public tables empty, then `OK` |
| 8 | Switch | speaker, agenda and tag pages serve; `OK` |
| 9 | Unfreeze and record | run noted below |

Beta checks step 5 against its own census, recorded on its run, since its data is not production's.

## Local Run

The local run rebuilds production's tenant rows first, as the parent's [Local Data](../tenant_consolidation.md#local-data) describes.

1. In production, run `agenda:backup` into the task's own disk.
2. Bring the dump home through the task log, and compare its SHA256.
3. Run `agenda:restore` on that directory.
4. Run steps 0 to 9 with production's `ASSETS_HOST`, taking a `pg_dump` of the local database as each restore point.

The production backup refuses on its census while 175 speakers lack slugs. It writes the dump first, so the refusal still leaves the dump step 2 brings home. Step 8 applies the switch commit locally and runs RSpec, Cucumber and the pages.

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
4. Run step 9, then mark group 8 complete in the parent document.

## Switch Commit

One commit, written in the local run's step 8 with RSpec and Cucumber green.

| File | Change |
|---|---|
| `config/initializers/apartment.rb` | add the eight models to `excluded_models` |
| the seven site models | plain `acts_as_tenant :site` |
| `app/models/agenda_tag.rb` | drop `acts_as_tenant` |
| `app/models/speaker.rb` | FriendlyId stays `:slugged` |
| speaker factory, features, admin specs | attach through `avatar_attachment` |
| the agenda task specs | include `with a group before its switch` |

A plain `acts_as_tenant` would hide every shared tag, whose `site_id` is null. FriendlyId's `:scoped` stays out: it regenerates a slug whenever `site_id` changes, which every new speaker's does, so it would overwrite each slug an editor gives.

## Recovery

A failed run is undone and run again whole; it never resumes.

| Where it stopped | What to do |
|---|---|
| Slug preparation | undo from the printed ids, or restore step 1 |
| Plan or preflight refused | fix it at the source, take a new backup |
| During the rows | run migrate again on the same run |
| During the avatars | `rollback[agenda]`, then migrate again |
| verify failed, before the switch | `rollback[agenda]`, fix, migrate again |
| After the switch deploy | revert the switch commit, deploy, then `rollback[agenda]` |
| Anything worse | restore step 4's restore point |

A redo reads the same dump, since each backfilled slug equals its speaker's id.
