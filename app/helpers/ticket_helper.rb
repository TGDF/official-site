# frozen_string_literal: true

module TicketHelper
  def ticket_name_for(plan)
    return t("ticket.type.#{plan}") unless ticket_early_bird?
    "#{t("ticket.type.#{plan}")} (#{t('ticket.early_bird')})"
  end

  def ticket_price_for(plan)
    plan = "early_#{plan}" if ticket_early_bird?
    current_site.send("ticket_#{plan}_price").to_i
  end

  def ticket_early_bird?
    current_site.ticket_early_bird_due_to > Time.zone.now
  end
end
