# frozen_string_literal: true

require 'rails_helper'

# Load the rake tasks once when this spec file is required (idempotent guard).
Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:consolidate')

# Integration tests for the in-place consolidate task, which the groups without dump
# tasks still move through: FK ID remapping, dry run, re-run guard, and the guards
# that refuse a group it must not move. Asset transfer is pinned on the dump path
# (game_migrate_spec.rb).
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

    it 'aborts the game group, which moves through the game tasks' do
      seed_game(main_site, name: { 'en' => 'Quest' })

      expect { run_task('tenant_consolidation:consolidate', 'game') }
        .to raise_error(SystemExit).and output(/tenant_consolidation:game:backup/).to_stdout
      expect(public_count(Game)).to eq(0)
    end

    it 'aborts attachment consolidation when a polymorphic record_id is set' do
      within_tenant(main_site) do
        Attachment.new(record_type: 'Foo', record_id: 123, file: 'x.png').save!(validate: false)
      end
      expect { run_task('tenant_consolidation:consolidate', 'attachment') }.to raise_error(SystemExit)
    end

    it 'aborts news consolidation when author_type is not AdminUser' do
      within_tenant(main_site) do
        news = News.new
        news[:title] = { 'en' => 'T' }
        news.slug = 'spec-news'
        news.author_type = 'Foo'
        news.author_id = 1
        news.save!(validate: false)
      end
      expect { run_task('tenant_consolidation:consolidate', 'news') }.to raise_error(SystemExit)
    end
  end

  describe 'consolidate[agenda] across two tenants' do
    let(:other_site) do
      create(:site, name: 'Other', domain: 'other.example.test', tenant_name: 'spec_cons_b')
    end

    before do
      seed_agenda_time(main_site, day_label: 'Day 1', time_label: 'Morning')
      seed_agenda_time(other_site, day_label: 'Day A', time_label: 'Evening')
      run_task('tenant_consolidation:consolidate', 'agenda')
    end

    it 'migrates every tenant\'s rows into public with the correct site_id' do
      in_public do
        expect(AgendaDay.unscoped.count).to eq(2)
        expect(AgendaTime.unscoped.pluck(:site_id)).to contain_exactly(main_site.id, other_site.id)
      end
    end

    it 'remaps agenda_time.day_id to each time\'s OWN migrated day (no stale/cross-tenant id)' do
      in_public do
        AgendaTime.unscoped.find_each do |time|
          day = AgendaDay.unscoped.find_by(id: time.day_id)
          expect(day).to be_present
          expect(day.site_id).to eq(time.site_id)
        end
      end
    end

    it 'aborts a re-run onto a non-empty public target' do
      expect { run_task('tenant_consolidation:consolidate', 'agenda') }.to raise_error(SystemExit)
    end

    it 'leaves the id sequence usable (a fresh insert does not hit a duplicate key)' do
      in_public do
        day = AgendaDay.new(site_id: main_site.id, label: 'Fresh')
        expect { day.save!(validate: false) }.not_to raise_error
        expect(day.id).to be_present
      end
    end
  end

  describe 'consolidate[agenda]' do
    it 'writes nothing to the public schema on a dry run' do
      seed_agenda_time(main_site, day_label: 'Day 1', time_label: '09:00')

      run_task('tenant_consolidation:consolidate', 'agenda', 'true')

      expect([ public_count(AgendaDay), public_count(AgendaTime) ]).to eq([ 0, 0 ])
    end
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
