# frozen_string_literal: true

require 'rails_helper'

RSpec.feature('Admin::Sliders', level: :feature) do
  let(:admin) { create(:admin_user) }
  let(:slider) { create(:slider) }

  before { sign_in admin }

  describe '#index' do
    before do
      @sliders = create_list(:slider, 5)
    end

    it 'can see all slider' do
      visit admin_sliders_path
      @sliders.each { |slider| expect(page).to(have_content(slider.id)) }
    end
  end

  describe '#new' do
    it 'can add new slider' do
      visit new_admin_slider_path
      attach_file(
        'slider_image',
        Rails.root.join('spec/support/brands/logos/TGDF.png')
      )
      click_button '新增Slider'
      expect(page).to(have_css("img[src*='TGDF.png']"))
    end
  end

  describe '#edit' do
    it 'can edit slider' do
      visit edit_admin_slider_path(slider)
      attach_file(
        'slider_image',
        Rails.root.join('spec/support/sliders/slide_1.jpg')
      )
      click_button '更新Slider'
      expect(page).to(have_css("img[src*='slide_1.jpg']"))
    end
  end

  describe '#destroy' do
    before { @slider = create(:slider) }

    it 'can destroy slider' do
      visit admin_sliders_path

      within first('td', text: @slider.id).first(:xpath, './/..') do
        click_on 'Destroy'
      end

      expect(page).not_to(have_content(@slider.id))
    end
  end
end
