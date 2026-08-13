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
    synchronize: 2,
    subtitle: 3
  }, prefix: :translated

  validates :subject, :description, presence: true
  validate :begin_and_end_are_presence

  # begin_at/end_at give a talk its own sub-time inside a shared AgendaTime
  # slot, and stay free text so an admin can type "16:30" directly. Keeping
  # only the clock part on write stops the stored shape from depending on
  # whichever input widget the admin form happens to use. A value holding no
  # clock time is stored untouched rather than discarded.
  def begin_at=(value)
    super(normalize_clock(value))
  end

  def end_at=(value)
    super(normalize_clock(value))
  end

  # A session counts as translated only when its translation targets a
  # different language than the original; same-language entries (e.g. a
  # Chinese talk marked as translated to Chinese) are treated as untranslated.
  def translated?
    translated_language.present? && translated_language != language
  end

  private

  def normalize_clock(value)
    text = value.to_s
    text[/\d{1,2}:\d{2}/] || text.presence
  end

  def begin_and_end_are_presence
    return unless begin_at.present? || end_at.present?

    errors.add(:begin_at, :blank) if begin_at.blank?
    errors.add(:end_at, :blank) if end_at.blank?
  end
end
