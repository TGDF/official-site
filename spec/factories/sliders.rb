# frozen_string_literal: true

FactoryBot.define do
  factory :slider do
    image do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec/support/brands/logos/TGDF.png'),
        'image/jpeg'
      )
    end

    # Mirrors a consolidated record in production: the CarrierWave marker was never
    # written back (slider predates marker retention) and ActiveStorage holds the file.
    trait :consolidated do
      image { nil }

      after(:build) do |slider|
        slider.image_attachment.attach(
          io: Rails.root.join('spec/support/brands/logos/TGDF.png').open,
          filename: 'TGDF.png',
          content_type: 'image/png'
        )
      end
    end
  end
end
