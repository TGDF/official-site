# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Admin::Sliders', level: :feature) do
  let(:admin) { create(:admin_user) }
  let(:slider) { create(:slider) }

  before { sign_in admin }

  describe '#index' do
    let!(:sliders) { create_list(:slider, 5) }

    it 'can see all slider' do
      visit admin_sliders_path
      sliders.each { |slider| expect(page).to(have_content(slider.id)) }
    end
  end

  describe '#new' do
    before do
      visit new_admin_slider_path
      attach_file(
        'slider_image',
        Rails.root.join('spec/support/brands/logos/TGDF.png')
      )
      click_on '新增Slider'
    end

    it { expect(page).to(have_css("img[src*='TGDF.png']")) }
  end

  describe '#edit' do
    before do
      visit edit_admin_slider_path(slider)
      attach_file(
        'slider_image',
        Rails.root.join('spec/support/sliders/slide_1.jpg')
      )
      click_on '更新Slider'
    end

    it { expect(page).to(have_css("img[src*='slide_1.jpg']")) }
  end

  describe '#destroy' do
    let!(:slider) { create(:slider) }

    it 'can destroy slider' do
      visit admin_sliders_path

      within first('td', text: slider.id).first(:xpath, './/..') do
        click_on 'Destroy'
      end

      expect(page).to(have_no_content(slider.id))
    end
  end
end
