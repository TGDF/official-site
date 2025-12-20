# frozen_string_literal: true

module Admin
  module UploadHelper
    # Returns the correct upload field name based on model's schema status.
    # Models in public schema (acts_as_tenant ready) use ActiveStorage.
    # Models in tenant schema (still using Apartment) use CarrierWave.
    #
    # @param model [ActiveRecord::Base] The model instance
    # @param field [Symbol] The base field name (e.g., :logo, :avatar)
    # @return [Symbol] The field name to use in forms (:logo_attachment or :logo)
    def upload_field_for(model, field)
      if model_ready_for_active_storage?(model)
        :"#{field}_attachment"
      else
        field
      end
    end

    private

    def model_ready_for_active_storage?(model)
      excluded = Apartment.excluded_models.map(&:to_s)
      excluded.include?(model.class.name)
    end
  end
end
