# frozen_string_literal: true

class Agenda < ApplicationRecord
  acts_as_tenant :site, optional: true, has_global_records: true

  translates :subject, :description

  has_many :agendas_speakers, dependent: :destroy
  has_many :speakers, through: :agendas_speakers

  has_many :taggings, class_name: "AgendasTagging", dependent: :delete_all
  has_many :tags, through: :taggings

  belongs_to :time, class_name: "AgendaTime",
                    inverse_of: :agendas, optional: true
  belongs_to :room, optional: true

  default_scope -> { order(order: :asc, id: :asc) }

  enum :language, {
    ZH: 1,
    EN: 2,
    JP: 3,
    KR: 4
  }

  enum :translated_language, {
    ZH: 1,
    EN: 2,
    JP: 3,
    KR: 4
  }, prefix: :translated

  enum :translated_type, {
    sentence: 1,
    synchornize: 2,
    subtitle: 3
  }

  validates :subject, :description, presence: true
  validate :begin_and_end_are_presence

  private

  def begin_and_end_are_presence
    return unless begin_at.present? || end_at.present?

    errors.add(:begin_at, :blank) if begin_at.empty?
    errors.add(:end_at, :blank) if end_at.empty?
  end
end
