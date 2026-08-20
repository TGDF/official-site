# frozen_string_literal: true

# The part of the tenant consolidation the running application has to know about.
#
# `consolidate` reads a group's tenant rows and then writes them into the public
# schema. A row written to the tenant schema after the read is not carried over, and
# it stops being reachable the moment the group enters `Apartment.excluded_models` —
# so the window that has to stay closed runs from the start of the data move until
# that configuration change is deployed, not just for the length of the run.
#
# The mechanics live in lib/tasks/tenant_consolidation.rake; the runbook is
# docs/tenant_consolidation.md ("Write-Freeze Posture").
module TenantConsolidation
  # Which group's data each admin screen writes. A screen missing from this table
  # writes nothing a consolidation moves — the dashboard, profiles, and the Site
  # screens (Site is already in the public schema and belongs to no group).
  #
  # Spec keeps the group names in step with the rake task's MIGRATION_GROUPS.
  ADMIN_SCREENS = {
    "admin/sliders" => "slider",
    "admin/blocks" => "block",
    "admin/plans" => "plan",
    "admin/menu_items" => "menu_item",
    "admin/games" => "game",
    "admin/indie_space/games" => "game",
    "admin/night_market/games" => "game",
    "admin/news" => "news",
    "admin/sponsors" => "sponsor",
    "admin/sponsor_levels" => "sponsor",
    "admin/partners" => "partner",
    "admin/partner_types" => "partner",
    "admin/speakers" => "agenda",
    "admin/agendas" => "agenda",
    "admin/agenda_days" => "agenda",
    "admin/agenda_times" => "agenda",
    "admin/agenda_tags" => "agenda",
    "admin/rooms" => "agenda",
    # CKEditor uploads land in Image, an STI subclass of Attachment.
    "admin/images" => "attachment"
  }.freeze

  class << self
    def group_for_screen(controller_path)
      ADMIN_SCREENS[controller_path]
    end

    def frozen?(group)
      group.present? && Flipper.enabled?(freeze_flag(group))
    end

    # Toggled from /flipper for the length of the window.
    def freeze_flag(group)
      :"consolidation_freeze_#{group}"
    end
  end
end
