# frozen_string_literal: true

module TicketHelper
  def ticket_name_for(plan)
    return t("ticket.type.#{plan}") unless ticket_early_bird?
    "#{t("ticket.type.#{plan}")} (#{t('ticket.early_bird')})"
  end

  def ticket_price_for(plan, early_bird = ticket_early_bird?)
    plan = "early_#{plan}" if early_bird
    current_site.send("ticket_#{plan}_price").to_i
  end

  def ticket_others_info_for(plan)
    others = t("ticket.info.#{plan}.others")
    return unless others.is_a?(Array)
    capture do
      others.each_with_index do |info, index|
        concat content_tag(:li, info, class: (index % 2).zero? ? 'gray-bg' : '')
      end
    end
  end

  def ticket_early_bird?
    current_site.ticket_early_bird_due_to > Time.zone.now
  end
end
