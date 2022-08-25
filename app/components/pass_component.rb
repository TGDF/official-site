# frozen_string_literal: true

class PassComponent < ViewComponent::Base
  with_collection_parameter :plan

  def initialize(plan:, site:)
    super
    @plan = plan
    @site = site
  end

  def early_bird?
    return false if @site.ticket_early_bird_due_to.blank?

    @site.ticket_early_bird_due_to > Time.zone.now
  end

  def name
    return t("ticket.type.#{@plan}") unless early_bird?

    "#{t("ticket.type.#{@plan}")} (#{t('ticket.early_bird')})"
  end

  def current_price
    return early_price if early_bird?

    price
  end

  def price
    @site.send("ticket_#{@plan}_price").to_i
  end

  def early_price
    @site.send("ticket_early_#{@plan}_price").to_i
  end

  def informations
    others = t("ticket.info.#{@plan}.others")
    return [] unless others.is_a?(Array)

    others
  end
end
