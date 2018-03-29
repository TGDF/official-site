# frozen_string_literal: true

class Site
  module HasTicketOptions
    extend ActiveSupport::Concern

    TICKET_OPTIONS = [
      # Price
      :ticket_student_price,
      :ticket_personal_price,
      :ticket_group_price,
      :ticket_early_student_price,
      :ticket_early_personal_price,
      :ticket_early_group_price,
      # Information
      :ticket_buy_link,
      :ticket_early_bird_due_to
    ].freeze

    included do
      store_accessor :options, *TICKET_OPTIONS

      validates :ticket_student_price, :ticket_personal_price,
                :ticket_group_price, :ticket_early_student_price,
                :ticket_early_personal_price, :ticket_early_personal_price,
                numericality: { allow_blank: true }

      def ticket_early_bird_due_to
        return Time.zone.now if super.nil?
        Time.zone.parse(super)
      end

      def ticket_early_bird_due_to=(date)
        date = case date
               when Hash then date.values.join('-')
               when Array then date.join('-')
               else date
               end
        date = Time.zone.parse(date.to_s)
        super
      end
    end
  end
end
