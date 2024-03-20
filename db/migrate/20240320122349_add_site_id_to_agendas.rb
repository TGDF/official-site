# frozen_string_literal: true

class AddSiteIdToAgendas < ActiveRecord::Migration[7.0]
  def change
    add_column :agendas, :site_id, :bigint
    add_index :agendas, :site_id

    add_column :agenda_days, :site_id, :bigint
    add_index :agenda_days, :site_id

    add_column :agenda_times, :site_id, :bigint
    add_index :agenda_times, :site_id

    add_column :agendas_speakers, :site_id, :bigint
    add_index :agendas_speakers, :site_id

    add_column :agenda_tags, :site_id, :bigint
    add_index :agenda_tags, :site_id

    add_column :agendas_taggings, :site_id, :bigint
    add_index :agendas_taggings, :site_id
  end
end
