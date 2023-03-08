# frozen_string_literal: true

Dir[Rails.root.join('app/uploaders/*.rb')].each { |file| require file }

RSpec.configure do |config|
  CarrierWave::Uploader::Base.descendants.each do |klass|
    next if klass.anonymous?

    klass.class_eval do
      def cache_dir
        Rails.root.join('spec/support/uploads/tmp')
      end

      def store_dir
        Rails.root.join(
          'spec',
          'support',
          'uploads',
          Apartment::Tenant.current,
          model.class.to_s.underscore,
          mounted_as.to_s,
          model.id.to_s
        )
      end
    end
  end

  config.after(:all) do
    FileUtils.rm_rf(Rails.root.join('spec/support/uploads'))
  end
end
