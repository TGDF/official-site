# Migrate: Agenda

Agenda moves through the same dump pipeline as [sponsor](migrate_sponsor.md) and [game](migrate_game.md), so this runbook covers what differs.

| | |
|---|---|
| Parent | [../tenant_consolidation.md](../tenant_consolidation.md), group 8 `agenda` |
| Status | 🔧 Preparing — no environment has run it |

## Moved Rows

The eight tables move together, because each points at another.

```
 AgendaDay ◀─day_id── AgendaTime ◀─time_id──┐
                            Room ◀─room_id── Agenda ◀─agenda_id── AgendasSpeaker ─speaker_id─▶ Speaker
 AgendaTag ◀─agenda_tag_id── AgendasTagging ─agenda_id─▶ Agenda
```

Every foreign key is rewritten to its own site's new parent through the plan's refs (`AgendaGroup::REFS`). Speaker's `avatar` moves into ActiveStorage. A null `time_id` or `room_id` stays null.

## Production Figures

The census re-takes these at backup, so trust the numbers it prints on the day.

| Measured read-only, 2026-10-29 | Figure |
|---|---|
| Sites | 9 |
| Days / times / rooms | 24 / 179 / 28 |
| Agendas / speakers | 406 / 371 |
| Speaker links / taggings | 412 / 562 |
| Tags | 93, merged into 23 shared |
| Taggings left out | 20, all in tgdf_2020 |
| Speakers without a slug | 175 before backfill |
| Avatar stand-in | tgdf_2020 Speaker#8 ← `v1_large` |

## Shared Tags

Tags are one vocabulary across every year. Each distinct tag becomes a single `AgendaTag` that belongs to no site.

| Source | Public |
|---|---|
| a tag per site, same `name` | one tag, `site_id` null |
| its timestamps | the first site's copy |
| every tagging | points at the shared tag |

Tags match on their whole `name`, every locale included. Production's 93 tags give exactly 23 names, with no name differing in one locale only. The census lists each shared tag with the tags it stands for. Tag management becomes shared in the admin, since every year now edits the same list.

## Left-out Taggings

A tagging whose tag or agenda is gone is left out, listed in the census and kept in the id map's `skipped`.

| tgdf_2020 | Detail |
|---|---|
| Taggings | 20, to AgendaTag #2 or #5 |
| Their agendas | all present |
| Cause | `287ea625`, 2020-06-20 |

Before that commit, deleting a tagging also deleted its tag. Removing agendas #28 and #38 on 2020-06-17 took tags #2 and #5 with them. The other agendas' taggings were left pointing at nothing, since the table has no database foreign key. Pages already hide them.

## Speaker Slugs

Every speaker must carry a slug before backup, so its `/speakers/<id>` link keeps resolving.

1. Run `backfill_speaker_slugs` inside the freeze; it writes each missing slug as the speaker's current id.
2. Run backup; a speaker still without a slug makes the plan refuse.
3. Run migrate; a save that rewrites any column aborts the run before its rows commit.

FriendlyId would make a slug from the name for a speaker saved without one. Its `:scoped` module regenerates a slug whenever `site_id` changes, so it joins only in the switch commit.

## Safety Net

Every layer answers a different failure.

| Layer | Catches | When |
|---|---|---|
| RDS snapshot | anything, by restoring | before the freeze |
| `consolidation_freeze_agenda` | admin edits on the old side | backup to switch |
| Census | missing files, stand-ins, left-out taggings, shared tags | backup |
| Plan | a slugless speaker, an unmapped key | backup, migrate |
| Write-time check | a column a save rewrote | migrate |
| `agenda:verify` | every row, ref, locale, avatar, shared tag | after migrate, after the switch |

`consolidate[agenda]` refuses and points here.

## Tasks

Each task runs as a detached one-off task on ECS.

```bash
bin/rails "tenant_consolidation:backfill_speaker_slugs[true]"  # dry run
bin/rails tenant_consolidation:backfill_speaker_slugs
bin/rails tenant_consolidation:agenda:backup
bin/rails "tenant_consolidation:agenda:migrate[<location>]"
bin/rails "tenant_consolidation:agenda:verify[<location>]"     # read-only; exits 1 on any problem
bin/rails "tenant_consolidation:rollback[agenda]"
```

Beta's speakers already carry slugs, so the backfill there writes nothing.

## Runbook

Beta rehearses the operations, the production dump rehearses the data locally, then production runs.

1. Check the event calendar, the deployed tooling, and that every public agenda table is empty.
2. On beta, enable `consolidation_freeze_agenda`, then run backup, migrate and verify until `OK`.
3. Locally, take the production dump read-only as in sponsor's step 2, then run migrate, verify and rollback.
4. In production, take an RDS snapshot and record its identifier.
5. Enable `consolidation_freeze_agenda`.
6. Run `backfill_speaker_slugs` as a dry run, then for real.
7. Run backup and read the census; stop on anything not in the figures above.
8. Download the run, then run migrate and verify until `OK`.
9. Push the switch commit, deploy beta then production, and run verify again.
10. Disable `consolidation_freeze_agenda` and mark group 8 complete in the parent document.

## Switch Commit

One commit, pushed only after production verify prints `OK`, with RSpec and Cucumber green.

| File | Change |
|---|---|
| `config/initializers/apartment.rb` | add the eight models to `excluded_models` |
| the seven site models | plain `acts_as_tenant :site` |
| `app/models/agenda_tag.rb` | drop `acts_as_tenant` |
| `app/models/speaker.rb` | FriendlyId `:scoped`, `scope: :site` |
| admin sidebar | tags under the shared section |
| speaker factory, features, admin specs | attach through `avatar_attachment` |
| the agenda task specs | include `with a group before its switch` |

A plain `acts_as_tenant` would hide every shared tag, whose `site_id` is null. The commit adds a spec that saving a moved speaker keeps its slug.

## Recovery

A failed run is undone and run again whole; it never resumes.

| Where it stopped | What to do |
|---|---|
| Plan or preflight refused | fix it at the source, take a new backup |
| During the rows | run migrate again on the same run |
| During the avatars | `rollback[agenda]`, then migrate again |
| verify failed, before the switch | `rollback[agenda]`, fix, migrate again |
| After the switch deploy | revert the switch commit, deploy, then `rollback[agenda]` |
| Anything worse | restore the snapshot from step 4 |

The backfilled slugs stay in the tenant schemas through any rollback. Each equals its speaker's id, so a redo reads the same dump.
