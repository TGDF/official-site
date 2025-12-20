# frozen_string_literal: true

class AgendaTag < ApplicationRecord
  acts_as_tenant :site, optional: true

  translates :name

  has_many :taggings, class_name: "AgendasTagging", dependent: :destroy
  has_many :agendas, through: :taggings
end
