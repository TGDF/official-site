# frozen_string_literal: true

class AgendasSpeaker < ApplicationRecord
  acts_as_tenant :site, optional: true, has_global_records: true

  belongs_to :agenda
  belongs_to :speaker
end
