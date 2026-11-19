# frozen_string_literal: true

require 'rails_helper'

# Load the rake tasks once when this spec file is required (idempotent guard).
Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:consolidate')

# Integration tests for the in-place consolidate task, which stays until the whole
# migration ends: attachment, the only group still listed for it, carries the move,
# dry run and re-run guard, beside the guards that refuse a group it must not move.
# Asset transfer is pinned on the dump path (game_migrate_spec.rb).
#
# Integration examples legitimately drive a whole flow and assert several outcomes,
# so the per-example RSpec metric cops are relaxed for this file.
# rubocop:disable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe 'tenant_consolidation rake tasks' do
  include_context 'with consolidation tenants'

  describe 'guard rails' do
    it 'aborts when no group is given' do
      expect { run_task('tenant_consolidation:consolidate') }.to raise_error(SystemExit)
    end

    context 'when sponsor is still in the tenant schemas' do
      include_context 'with a group before its switch', TenantConsolidation::SponsorGroup

      it 'aborts the sponsor group, which moves through the sponsor tasks' do
        seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' })

        expect { run_task('tenant_consolidation:consolidate', 'sponsor') }.to raise_error(SystemExit)
        expect(public_count(Sponsor)).to eq(0)
      end
    end

    it 'aborts the retired partner group, which folds into sponsor' do
      expect { run_task('tenant_consolidation:consolidate', 'partner') }.to raise_error(SystemExit)
    end

    context 'when game is still in the tenant schemas' do
      include_context 'with a group before its switch', TenantConsolidation::GameGroup

      it 'aborts the game group, which moves through the game tasks' do
        seed_game(main_site, name: { 'en' => 'Quest' })

        expect { run_task('tenant_consolidation:consolidate', 'game') }
          .to raise_error(SystemExit).and output(/tenant_consolidation:game:backup/).to_stdout
        expect(public_count(Game)).to eq(0)
      end
    end

    context 'when agenda is still in the tenant schemas' do
      include_context 'with a group before its switch', TenantConsolidation::AgendaGroup

      it 'aborts the agenda group, which moves through the agenda tasks' do
        seed_agenda_time(main_site, day_label: 'Day 1', time_label: 'Morning')

        expect { run_task('tenant_consolidation:consolidate', 'agenda') }
          .to raise_error(SystemExit).and output(/tenant_consolidation:agenda:backup/).to_stdout
        expect(public_count(AgendaDay)).to eq(0)
      end
    end

    it 'sends a dump group to its own verify, which checks every row against its dump' do
      expect { run_task('tenant_consolidation:verify', 'agenda') }
        .to raise_error(SystemExit).and output(/tenant_consolidation:agenda:verify\[<run location>\]/).to_stdout
    end

    it 'names every group, dump groups included, when none is given' do
      expect { run_task('tenant_consolidation:rollback') }
        .to raise_error(SystemExit).and output(/tenant_consolidation:rollback\[slider\].*agenda: AgendaDay/m).to_stdout
    end

    it 'aborts attachment consolidation when a polymorphic record_id is set' do
      within_tenant(main_site) do
        Attachment.new(record_type: 'Foo', record_id: 123, file: 'x.png').save!(validate: false)
      end
      expect { run_task('tenant_consolidation:consolidate', 'attachment') }.to raise_error(SystemExit)
    end

    context 'when news is still in the tenant schemas' do
      include_context 'with a group before its switch', TenantConsolidation::NewsGroup

      it 'aborts the news group, which moves through the news tasks' do
        seed_news(main_site, slug: 'opening', title: { 'en' => 'Opening' })

        expect { run_task('tenant_consolidation:consolidate', 'news') }
          .to raise_error(SystemExit).and output(/tenant_consolidation:news:backup/).to_stdout
        expect(public_count(News)).to eq(0)
      end
    end
  end

  describe 'consolidate[attachment] across two tenants' do
    let(:other_site) { create_tenant_site('spec_cons_b') }

    def seed_attachment(site)
      within_tenant(site) { Attachment.new(site_id: site.id).save!(validate: false) }
    end

    before do
      seed_attachment(main_site)
      seed_attachment(other_site)
      run_task('tenant_consolidation:consolidate', 'attachment')
    end

    it 'migrates every tenant\'s rows into public with the correct site_id' do
      in_public do
        expect(Attachment.unscoped.pluck(:site_id)).to contain_exactly(main_site.id, other_site.id)
      end
    end

    it 'aborts a re-run onto a non-empty public target' do
      expect { run_task('tenant_consolidation:consolidate', 'attachment') }.to raise_error(SystemExit)
    end

    it 'leaves the id sequence usable (a fresh insert does not hit a duplicate key)' do
      in_public do
        attachment = Attachment.new(site_id: main_site.id)
        expect { attachment.save!(validate: false) }.not_to raise_error
        expect(attachment.id).to be_present
      end
    end
  end

  describe 'consolidate[attachment]' do
    it 'writes nothing to the public schema on a dry run' do
      within_tenant(main_site) { Attachment.new(site_id: main_site.id).save!(validate: false) }

      run_task('tenant_consolidation:consolidate', 'attachment', 'true')

      expect(public_count(Attachment)).to eq(0)
    end
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
