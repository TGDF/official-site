# frozen_string_literal: true

class SetDefaultValueForI18nColumns < ActiveRecord::Migration[7.1]
  def change # rubocop:disable Metrics/AbcSize
    change_column_default :agenda_tags, :name, from: nil, to: {}

    change_table :agendas, bulk: true do |t|
      t.change_default :subject, from: nil, to: {}
      t.change_default :description, from: nil, to: {}
    end

    change_table :games, bulk: true do |t|
      t.change_default :name, from: nil, to: {}
      t.change_default :description, from: nil, to: {}
      t.change_default :team, from: nil, to: {}
    end

    change_table :menu_items, bulk: true do |t|
      t.change_default :name, from: nil, to: {}
      t.change_default :link, from: nil, to: {}
    end

    change_table :news, bulk: true do |t|
      t.change_null :title, false
      t.change_default :title, from: nil, to: {}
      t.change_default :content, from: nil, to: {}
    end

    change_column_default :partner_types, :name, from: nil, to: {}

    change_table :partners, bulk: true do |t|
      t.change_default :name, from: nil, to: {}
      t.change_default :description, from: nil, to: {}
    end

    change_table :plans, bulk: true do |t|
      t.change_default :name, from: nil, to: {}
      t.change_default :content, from: nil, to: {}
      t.change_default :button_label, from: nil, to: {}
      t.change_default :button_target, from: nil, to: {}
    end

    change_table :sites, bulk: true do |t|
      t.change_default :name, from: nil, to: {}
      t.change_default :description, from: nil, to: {}
      t.change_default :indie_space_description, from: nil, to: {}
    end

    change_table :speakers, bulk: true do |t|
      t.change_default :name, from: nil, to: {}
      t.change_default :description, from: nil, to: {}
      t.change_default :title, from: nil, to: {}
    end

    change_column_default :sponsor_levels, :name, from: nil, to: {}

    change_table :sponsors, bulk: true do |t|
      t.change_default :name, from: nil, to: {}
      t.change_default :description, from: nil, to: {}
    end
  end
end
