# frozen_string_literal: true

class AgendasSpeaker < ApplicationRecord
  belongs_to :agenda
  belongs_to :speaker
end
