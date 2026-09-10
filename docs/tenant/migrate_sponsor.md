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

Partner is retired: it is never consolidated as Partner rows. Its tenant rows stay where they are, and its code goes in Phase 5.

Measured in production (read-only; figures from the parent's *Measured state*, re-taken by the census at backup time):

| | Figure | As of |
|---|---|---|
| Sponsor logos in CarrierWave | 206 | 2026-08-20 |
| Sponsors with `site_id IS NULL` | 155 — the move gives every row its site | 2026-08-20 |
| Sponsors per tenant | 2018–2022: 26–33 each; 2025tgdf: 23 across 8 levels; 2026tgdf: not yet counted | 2025-12-20 |
| Partners | 48 — 2023tgdf 27 across 8 types, 2024tgdf 21 across 6 types | 2025-12-20, re-confirmed 2026-08-20 |
| SponsorLevels / Sponsors in 2023tgdf and 2024tgdf | 0 — no level reuse and no skipped partner expected | 2025-12-20 |
| Embedded `/uploads/` in `Sponsor.description` | 0 | 2026-08-20 |

## The shape

The move is three tasks around one reviewed file. Each can be run, read and repeated on its own.

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
                                         └─ logos, one transaction each ──────▶ ActiveStorage (size = dump)
                                                                       │
                                   sponsor:verify ◀── Transform(dump) + id_map ─▶ OK / every problem, exit 1
```

`Transform` is the single statement of what each site becomes. The census prints it before anything is written, migrate writes exactly it, and verify compares public against it. Because verify replans with the same rules the import used, the rules themselves are pinned by specs with literal outcomes (`spec/lib/tasks/sponsor_migrate_spec.rb`, `sponsor_journey_spec.rb`).

```
 SponsorLevel ────────────────────────────────────────▶ level
 PartnerType ── a same-site level has that name? ── yes ─▶ (reuses it)
                                                └── no ──▶ level; 2023tgdf label corrected
 Sponsor ─────────────────────────────────────────────▶ sponsor under its level
 Partner ─── its name already taken in the site? ── yes ─▶ skipped, listed for review
                                                 └── no ──▶ sponsor under its type's level
```

Names compare as the whole JSONB value, every locale at once. **2023tgdf's PartnerType labels** pair English and Chinese the other way round from every other year; the transform gives them the labels every other year uses:

| English label | 2023tgdf holds | Becomes |
|---|---|---|
| Supporting Partners | 協辦單位 | 合作單位 |
| Co-organizers | 合作單位 | 協辦單位 |

## The safety net

Every layer answers a different failure. None of them relies on the one after it.

| Layer | Catches | When |
|---|---|---|
| RDS snapshot | anything, by restoring the database | before the freeze |
| Write freeze (`consolidation_freeze_sponsor`, `_partner`) | an admin edit landing on the side about to be abandoned | from backup until the switch deploy is live |
| Dump in S3, downloaded | the reviewed input, kept outside the database; a re-run imports exactly it | backup |
| Census | missing logo files, leftover ActiveStorage rows on Sponsor ids, partners that will be skipped, labels that will change | backup, before anything is written |
| Preflight refusal | Sponsor already public, public rows already present, a dumped tenant with no `Site`, a foreign key the dump cannot resolve, a missing logo, a leftover attachment | migrate, before anything is written |
| One transaction for all rows | a half-moved site | migrate |
| Write-time raises | a lost locale; a logo whose downloaded size differs from the source (a CDN's 200 + HTML page) | migrate |
| `sponsor:verify` | a missing or extra row, a wrong site or level, a changed column, a lost locale, a missing or wrong-sized logo | after migrate, and again after the switch |
| Specs | each promise above, proven by breaking it on purpose | CI |

Two things the dump does not cover, by design. It is not a restore path — the snapshot is. And it does not hold the logo bytes: those stay in `uploads/` on S3, untouched by the move, and are only deleted in Phase 5.5 behind its own gate.

`updated_at` is the one column verify does not compare on a sponsor whose logo was attached, since attaching touches the record (`ActiveStorage.touch_attachment_records`). It is compared everywhere else.

## Tasks

```bash
bin/rails tenant_consolidation:sponsor:backup                 # new run in the bucket (tmp/ locally)
bin/rails "tenant_consolidation:sponsor:backup[<location>]"   # or a location of your choosing
bin/rails "tenant_consolidation:sponsor:migrate[<location>]"  # needs the run backup printed
bin/rails "tenant_consolidation:sponsor:verify[<location>]"   # read-only; exits 1 on any problem
bin/rails "tenant_consolidation:rollback[sponsor]"            # clears public SponsorLevel/Sponsor
```

A location is a local directory or `s3://<application bucket>/consolidation/…`; anything else is refused. `consolidate[sponsor]` and `consolidate[partner]` stop and point here.

On ECS, run each as a **detached one-off task** so a dropped shell cannot cut a run short. The container's entrypoint is `bin/openbox`, which runs `rake <task>`; the output lands in the task's CloudWatch log stream.

## Runbook

```
            beta (own data)          local (production dump)        production
            ───────────────          ───────────────────────        ──────────
 rehearse   freeze → backup →        backup(prod) → download →      ·
            migrate → verify         migrate → verify → rollback
 run        ·                        ·                              snapshot → freeze → backup →
                                                                    download → migrate → verify
 switch     auto-deploys first  ◀─── push the switch commit ───▶    waits for approval
            check it                                                approve → check → verify → unfreeze sponsor
```

Beta has little data, so it rehearses the **operations** — the freeze, the tasks on ECS, the deploy order. The **data** is rehearsed locally, against the production dump.

### 0. Before starting

- [ ] Not near the annual event.
- [ ] This tooling is deployed to the environment (the tasks exist there).
- [ ] `tenant_consolidation:status` shows sponsor pending, and public `sponsor_levels` / `sponsors` are empty.
- [ ] No ActiveStorage attachment sits on a `Sponsor` id — the census and preflight both report one. It would land on whichever new public sponsor takes that id. `cleanup_attachments` purges those whose id matches a tenant row; one that matches no row has to be removed by hand.

### 1. Beta — rehearse the operations

1. Enable `consolidation_freeze_sponsor` and `consolidation_freeze_partner` in beta's `/flipper`.
2. `sponsor:backup` → read the census.
3. `sponsor:migrate[<location>]` → `sponsor:verify[<location>]` must print `OK`.
4. Leave beta migrated and frozen: the switch commit deploys to beta first and needs its data in public. If the production run is postponed, run `rollback[sponsor]` on beta and lift the freeze.

### 2. Local — rehearse the data with the production dump

1. Take a production backup. It only reads, so it can run before the freeze; its purpose here is the rehearsal, not the real run.
2. Bring it home: `aws s3 cp s3://<bucket>/consolidation/sponsor/<time> ./<time> --recursive --profile tgdf`.
3. Locally, give every dumped tenant a `Site` (migrate refuses a tenant it cannot find):

   ```bash
   bin/rails runner '
     JSON.parse(File.read("<time>/dump.json"))["sites"].each do |s|
       Site.find_or_create_by!(tenant_name: s["tenant_name"]) do |site|
         site.name = s["tenant_name"]
         site.domain = "#{s["tenant_name"].downcase.tr("_", "-")}.localhost.test"
       end
     end'
   ```

4. `bin/rails "tenant_consolidation:sponsor:migrate[<time>]"` — logos download from the production CDN, which is public.
5. `bin/rails "tenant_consolidation:sponsor:verify[<time>]"` must print `OK`.
6. `bin/rails "tenant_consolidation:rollback[sponsor]"` to leave the local database as it was.

### 3. Production — the run

1. RDS snapshot, with one exact identifier recorded for this run (the parent's *Create RDS Snapshot*).
2. Enable `consolidation_freeze_sponsor` and `consolidation_freeze_partner`. From here until the switch deploy is live, an admin edit to either group would be lost.
3. `sponsor:backup` → read the census. **Stop** on a missing logo, a leftover attachment, or a count or skipped partner you did not expect.
4. Download the run (step 2.2) and keep it.
5. `sponsor:migrate[<location>]`, then `sponsor:verify[<location>]` — it must print `OK`.

### 4. The switch commit

One commit, pushed only after step 3 prints `OK`:

- [ ] `config/initializers/apartment.rb` — add `SponsorLevel` and `Sponsor` to `excluded_models`. Never `Partner` / `PartnerType`.
- [ ] `app/models/sponsor.rb`, `app/models/sponsor_level.rb` — plain `acts_as_tenant :site` (drop `optional:` and `has_global_records:`).
- [ ] Stop reading Partner where the public sees it — every partner is now a sponsor, and would otherwise show twice:
  - `app/controllers/pages_controller.rb` — `@partners_and_sponsors` from Sponsor only
  - `app/views/pages/index.html.erb` — render the block on `Sponsor.exists?`
  - `app/controllers/sponsors_controller.rb` and `app/views/sponsors/index.html.erb` — drop `@partner_types`
- [ ] Tests follow ActiveStorage, so they exercise the path production now takes rather than the CarrierWave fallback:
  - `features/admin/admin_sponsors.feature` — the attached field is `logo_attachment`
  - `features/step_definitions/sponsor.rb`, `spec/factories/sponsors.rb` — attach the logo through `logo_attachment`
- [ ] RSpec and Cucumber green.

The Partner admin screens stay, behind `consolidation_freeze_partner`, until Phase 5 removes Partner.

### 5. Deploy and close the window

1. Push. Beta deploys on its own; check its sponsor pages and admin form.
2. Approve the production deploy. Check the sponsor pages, the admin form (the upload field is `logo_attachment`), and that logo URLs are ActiveStorage ones.
3. `sponsor:verify[<location>]` again — it reads the public schema whichever side the switch is on, and must still print `OK`.
4. Disable `consolidation_freeze_sponsor`. Leave `consolidation_freeze_partner` on.
5. In the parent document, mark groups 5 and 6 complete.

```
 freeze ─┬─ backup ── migrate ── verify ── switch commit ── deploy (beta → prod) ─┬─ unfreeze sponsor
         │                                                                        │
         └────────── an admin write here lands in the tenant schema and is lost ──┘
```

## Recovery

| Where it stopped | State | What to do |
|---|---|---|
| Preflight refused | nothing written | fix what it named at the source, take a new backup |
| During the rows | nothing written — one transaction | fix the cause, run migrate again on the same run |
| During the logos | rows and id map in public, some logos missing | `rollback[sponsor]`, then migrate again on the same run |
| verify failed, before the switch | rows in public, not served | `rollback[sponsor]`, fix, migrate again |
| After the switch deploy | public rows are live | revert the switch commit and deploy it, then `rollback[sponsor]` |
| Anything worse | — | restore the snapshot recorded in step 3.1 (the parent's *Rollback Strategy*, Level 3) |

`rollback[sponsor]` refuses while `Sponsor` is in `excluded_models`, and deletes every public `SponsorLevel` and `Sponsor` — the merged partners included, which is what makes a clean re-run possible before the switch. The tenant rows are never touched by any of this.

Keep the run directory. It is the reviewed input and the only record of which tenant row became which public row.
