# frozen_string_literal: true

class AgendasTagging < ApplicationRecord
  acts_as_tenant :site, optional: true, has_global_records: true

  belongs_to :agenda, dependent: :destroy, inverse_of: :taggings
  belongs_to :tag, class_name: 'AgendaTag', dependent: :destroy,
                   foreign_key: :agenda_tag_id, inverse_of: :taggings
end
