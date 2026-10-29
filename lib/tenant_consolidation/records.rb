# frozen_string_literal: true

module TenantConsolidation
  # Row-level handling shared by every consolidation path: a row is read and written
  # through its raw columns so Mobility's JSONB translations keep every locale, and
  # checked after its save against what was written.
  module Records
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

    # The Mobility JSONB attributes the model declares with `translates` — the columns
    # whose locale set is checked after each write, since a lost locale would
    # otherwise pass silently.
    def translated_attributes(model_name)
      model = model_name.constantize
      model.respond_to?(:mobility_attributes) ? model.mobility_attributes : []
    end

    def capture_source_translations(record, model_name)
      translated_attributes(model_name).to_h { |attr| [ attr, record[attr] ] }
    end

    def verify_translations_preserved(source_translations, new_record, model_name)
      translated_attributes(model_name).each do |attr|
        source_locales = (source_translations[attr] || {}).keys.sort
        new_locales = (new_record[attr] || {}).keys.sort
        if source_locales != new_locales
          raise "Translation loss detected for #{model_name}##{new_record.id}.#{attr}: " \
                "expected #{source_locales}, got #{new_locales}"
        end
      end
    end

    # Raises on any column a save left different from what was written — a callback
    # such as FriendlyId's slug generation would otherwise rewrite it silently.
    def verify_written_as_planned(attrs, record, model_name)
      attrs.each do |column, value|
        expected = record.class.type_for_attribute(column).cast(value)
        next if record[column] == expected

        raise "#{model_name}##{record.id}.#{column} was written as #{record[column].inspect}, " \
              "planned #{expected.inspect}"
      end
    end
  end
end
