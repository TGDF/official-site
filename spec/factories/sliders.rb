# frozen_string_literal: true

FactoryBot.define do
  factory :slider do
    image do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec', 'support', 'brands', 'logos', 'TGDF.png'),
        'image/jpeg'
      )
    end
  end
end
