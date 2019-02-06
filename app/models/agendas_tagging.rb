# frozen_string_literal: true

class AgendasTagging < ApplicationRecord
  belongs_to :agenda, dependent: :delete, inverse_of: :taggings
  belongs_to :tag, class_name: 'AgendaTag', dependent: :delete,
                   foreign_key: :agenda_tag_id, inverse_of: :taggings
end
