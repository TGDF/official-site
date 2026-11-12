# frozen_string_literal: true

class AgendasTagging < ApplicationRecord
  acts_as_tenant :site

  belongs_to :agenda, inverse_of: :taggings
  belongs_to :tag, class_name: "AgendaTag", foreign_key: :agenda_tag_id, inverse_of: :taggings
end
