# frozen_string_literal: true

module TenantConsolidation
  # Row-level handling shared by every consolidation path: a row is read and written
  # through its raw columns so Mobility's JSONB translations keep every locale, and a
  # foreign key is only ever rewritten to a parent this run has already migrated.
  module Records
    # Mobility JSONB attributes per model — the columns whose locale set is checked
    # after each write, since a lost locale would otherwise pass silently.
    TRANSLATED_ATTRS = {
      "Plan" => %w[name content button_label button_target],
      "Sponsor" => %w[name description],
      "SponsorLevel" => %w[name],
      "Partner" => %w[name description],
      "PartnerType" => %w[name],
      "Game" => %w[name description team],
      "News" => %w[title content],
      "Speaker" => %w[name title description],
      "Agenda" => %w[subject description],
      "AgendaTag" => %w[name],
      "MenuItem" => %w[name link]
    }.freeze

    module_function

    # Reads through `record[name]`, bypassing Mobility's attribute_methods plugin, which
    # would return the current locale only.
    def extract_raw_attributes(record, *excluded_fields)
      excluded = [ "id" ] + excluded_fields.compact.map(&:to_s)
      record.attribute_names
            .reject { |name| excluded.include?(name) }
            .to_h { |name| [ name, record[name] ] }
            .compact
    end

    # Writes through `record[attr] =`, bypassing Mobility's writer plugin, which would
    # nest a locale hash under the current locale.
    def assign_raw_attributes(record, attrs)
      attrs.each do |attr, value|
        record[attr] = value
      end
    end

    def capture_source_translations(record, model_name)
      translated_attrs = TRANSLATED_ATTRS[model_name] || []
      translated_attrs.to_h { |attr| [ attr, record[attr] ] }
    end

    def verify_translations_preserved(source_translations, new_record, model_name)
      translated_attrs = TRANSLATED_ATTRS[model_name] || []
      translated_attrs.each do |attr|
        source_locales = (source_translations[attr] || {}).keys.sort
        new_locales = (new_record[attr] || {}).keys.sort
        if source_locales != new_locales
          raise "Translation loss detected for #{model_name}##{new_record.id}.#{attr}: " \
                "expected #{source_locales}, got #{new_locales}"
        end
      end
    end

    # Rewrites each foreign key in `attrs` to its parent's new id. A parent missing from
    # `id_maps` means an orphaned source row; raising keeps a stale tenant id from being
    # persisted — silently, on tables with no database foreign key (agendas_taggings).
    def remap_foreign_keys(attrs, fk_mappings, id_maps, model_name)
      fk_mappings.each do |fk_column, parent_model|
        old_fk_value = attrs[fk_column.to_s]
        next unless old_fk_value

        new_fk_value = id_maps[parent_model][old_fk_value]
        if new_fk_value.nil?
          raise "Cannot remap #{model_name}.#{fk_column}=#{old_fk_value} " \
                "(#{parent_model} not in id_maps — orphaned source row)"
        end
        attrs[fk_column.to_s] = new_fk_value
      end
    end
  end
end
