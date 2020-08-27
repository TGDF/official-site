# frozen_string_literal: true

FactoryBot.define do
  factory :partner do
    name { Faker::Name.name }
    logo do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec/support/brands/logos/TGDF.png'),
        'image/jpeg'
      )
    end
    type { create(:partner_type) }
  end
end
