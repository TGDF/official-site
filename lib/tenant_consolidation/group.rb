# frozen_string_literal: true

module TenantConsolidation
  # What every dump group answers, read by the backup, migrate and verify tasks. A
  # group extends this and declares its rows as constants:
  #
  #   NAME     the group's name in task names and runbooks
  #   MODELS   the dumped models, parents first
  #   UPLOADS  each model's CarrierWave field that moves into ActiveStorage
  #   TARGETS  the public models it writes, when they are not MODELS
  #   SHARED   the targets written once for every site, when there are any
  #
  # A group whose rows move as they are needs nothing more; one with its own rules
  # defines `plan`, and `census_sections` for what the census should list about them.
  module Group
    def self.find(name) = TenantConsolidation.const_get("#{name.camelize}Group")

    def group_name = self::NAME
    def models = self::MODELS
    def uploads = self::UPLOADS
    def targets = const_defined?(:TARGETS, false) ? self::TARGETS : models
    def shared = const_defined?(:SHARED, false) ? self::SHARED : []
    def shared?(model) = shared.include?(model)

    def plan(site) = Plan.carry(site, models)

    def census_sections(_dump) = []
  end
end
