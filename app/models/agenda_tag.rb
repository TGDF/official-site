# frozen_string_literal: true

class AgendaTag < ApplicationRecord
  # One vocabulary shared by every year: a tag belongs to no site, so no tenant
  # scope may hide it.
  translates :name

  has_many :taggings, class_name: "AgendasTagging", dependent: :destroy
  has_many :agendas, through: :taggings
end
