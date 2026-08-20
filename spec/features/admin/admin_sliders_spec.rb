# frozen_string_literal: true

require 'rails_helper'

# Slider is consolidated into the public schema, so `image_url` serves the
# ActiveStorage attachment (docs/tenant/dual_system.md decision table). The admin
# form's removal checkbox and its file field must act on that same attachment.
RSpec.describe('Admin::Sliders uploads') do
  let(:admin) { create(:admin_user) }
  let(:slider) { create(:slider, :consolidated) }

  before { sign_in admin }

  describe 'removing a required image' do
    before do
      visit edit_admin_slider_path(slider)
      check 'slider_remove_image'
      click_on '更新Slider'
    end

    it 'keeps the image attached' do
      expect(slider.reload.image_attachment).to(be_attached)
    end

    it 'tells the admin the image cannot be blank' do
      expect(page).to(have_text(I18n.t('errors.messages.blank')))
    end
  end

  describe 'editing without choosing a file' do
    before do
      visit edit_admin_slider_path(slider)
      select 'English', from: 'slider_language'
      click_on '更新Slider'
    end

    it 'keeps the image attached' do
      expect(slider.reload.image_attachment).to(be_attached)
    end

    it 'saves the edit' do
      expect(slider.reload.language).to(eq('en'))
    end
  end
end
