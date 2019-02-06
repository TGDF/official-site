# frozen_string_literal: true

class AgendaTag < ApplicationRecord
  translates :name

  has_many :taggings, class_name: 'AgendasTagging', dependent: :destroy
  has_many :agendas, through: :taggings
end
