# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:consolidate')

# `consolidate` reads a group's tenant rows, then writes them into the public schema.
# Anything the admin writes in between lands in the schema the move has already read
# and is lost at the cutover, so those screens have to stop accepting writes for the
# whole window — the run, the verification, and the deploy that switches the models
# over. docs/tenant_consolidation.md, "Write-Freeze Posture".
RSpec.describe('Admin consolidation freeze') do
  let(:slider) { create(:slider) }

  before { sign_in(create(:admin_user)) }

  def rename_slider
    patch(admin_slider_path(slider), params: { slider: { interval: 9999 } })
  end

  context 'when the screen\'s group is frozen' do
    before { Flipper.enable(TenantConsolidation.freeze_flag('slider')) }

    it 'refuses the write' do
      expect { rename_slider }.not_to(change { slider.reload.interval })
    end

    it 'sends the admin back with an explanation' do
      rename_slider

      expect(flash[:alert]).to(eq(I18n.t('admin.errors.consolidation_frozen')))
    end
  end

  context 'when another group is frozen' do
    before { Flipper.enable(TenantConsolidation.freeze_flag('agenda')) }

    it 'leaves this screen writable' do
      expect { rename_slider }.to(change { slider.reload.interval }.to(9999))
    end
  end

  context 'without any freeze' do
    it 'leaves the screen writable' do
      expect { rename_slider }.to(change { slider.reload.interval }.to(9999))
    end
  end

  # A group nobody can freeze is a hole in the runbook, so the screen table has to
  # name every group the rake task knows how to move.
  it 'covers every migration group' do
    expect(TenantConsolidation::ADMIN_SCREENS.values.uniq).to(match_array(MIGRATION_GROUPS.keys))
  end
end
