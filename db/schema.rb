# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_03_26_124034) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_sign_in_at", precision: nil
    t.inet "last_sign_in_ip"
    t.datetime "locked_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unlock_token"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_admin_users_on_unlock_token", unique: true
  end

  create_table "agenda_days", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.date "date", default: -> { "now()" }, null: false
    t.string "label"
    t.bigint "site_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["site_id"], name: "index_agenda_days_on_site_id"
  end

  create_table "agenda_tags", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.jsonb "name", default: {}
    t.bigint "site_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["site_id"], name: "index_agenda_tags_on_site_id"
  end

  create_table "agenda_times", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "day_id"
    t.string "label"
    t.integer "order", default: 0, null: false
    t.boolean "single"
    t.bigint "site_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["day_id"], name: "index_agenda_times_on_day_id"
    t.index ["site_id"], name: "index_agenda_times_on_site_id"
  end

  create_table "agendas", force: :cascade do |t|
    t.string "begin_at"
    t.datetime "created_at", precision: nil, null: false
    t.jsonb "description", default: {}
    t.string "end_at"
    t.integer "language"
    t.integer "order", default: 0, null: false
    t.bigint "room_id"
    t.bigint "site_id"
    t.jsonb "subject", default: {}
    t.bigint "time_id"
    t.integer "translated_language"
    t.integer "translated_type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["room_id"], name: "index_agendas_on_room_id"
    t.index ["site_id"], name: "index_agendas_on_site_id"
    t.index ["time_id"], name: "index_agendas_on_time_id"
  end

  create_table "agendas_speakers", force: :cascade do |t|
    t.bigint "agenda_id"
    t.datetime "created_at", precision: nil, null: false
    t.bigint "site_id"
    t.bigint "speaker_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["agenda_id"], name: "index_agendas_speakers_on_agenda_id"
    t.index ["site_id"], name: "index_agendas_speakers_on_site_id"
    t.index ["speaker_id"], name: "index_agendas_speakers_on_speaker_id"
  end

  create_table "agendas_taggings", force: :cascade do |t|
    t.bigint "agenda_id"
    t.bigint "agenda_tag_id"
    t.datetime "created_at", precision: nil, null: false
    t.bigint "site_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["site_id"], name: "index_agendas_taggings_on_site_id"
  end

  create_table "attachments", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "file"
    t.bigint "record_id"
    t.string "record_type"
    t.bigint "site_id"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["site_id"], name: "index_attachments_on_site_id"
  end

  create_table "blocks", force: :cascade do |t|
    t.string "component_type", default: "text", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.string "language", default: "zh-TW", null: false
    t.integer "order", default: 0, null: false
    t.string "page", null: false
    t.bigint "site_id"
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_blocks_on_site_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.jsonb "description", default: {}, null: false
    t.jsonb "name", default: {}, null: false
    t.integer "order", default: 0
    t.bigint "site_id"
    t.jsonb "team", default: {}, null: false
    t.string "thumbnail"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.string "video"
    t.string "website"
    t.index ["site_id"], name: "index_games_on_site_id"
  end

  create_table "menu_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "link", default: {}
    t.string "menu_id"
    t.jsonb "name", default: {}
    t.integer "position", default: 0, null: false
    t.bigint "site_id"
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["site_id"], name: "index_menu_items_on_site_id"
  end

  create_table "news", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.jsonb "content", default: {}
    t.datetime "created_at", precision: nil, null: false
    t.bigint "site_id"
    t.string "slug", null: false
    t.integer "status", default: 0
    t.string "thumbnail"
    t.jsonb "title", default: {}, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["author_type", "author_id"], name: "index_news_on_author_type_and_author_id"
    t.index ["site_id", "slug"], name: "index_news_on_site_id_and_slug", unique: true
    t.index ["status"], name: "index_news_on_status"
  end

  create_table "partner_types", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.jsonb "name", default: {}
    t.integer "order", default: 0
    t.bigint "site_id"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "partners", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.jsonb "description", default: {}
    t.string "logo"
    t.jsonb "name", default: {}
    t.integer "order", default: 0
    t.bigint "site_id"
    t.bigint "type_id"
    t.datetime "updated_at", precision: nil, null: false
    t.string "url"
    t.index ["site_id", "type_id"], name: "index_partners_on_site_id_and_type_id"
    t.index ["type_id"], name: "index_partners_on_type_id"
  end

  create_table "plans", force: :cascade do |t|
    t.jsonb "button_label", default: {}
    t.jsonb "button_target", default: {}
    t.jsonb "content", default: {}
    t.datetime "created_at", null: false
    t.jsonb "name", default: {}
    t.integer "order", default: 0, null: false
    t.bigint "site_id"
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_plans_on_site_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name"
    t.integer "order", default: 0, null: false
    t.bigint "site_id"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "sites", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.jsonb "description", default: {}
    t.string "domain", null: false
    t.string "figure"
    t.jsonb "indie_space_description", default: {}
    t.string "logo"
    t.jsonb "name", default: {}
    t.jsonb "options"
    t.string "tenant_name"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["domain"], name: "index_sites_on_domain"
    t.index ["tenant_name"], name: "index_sites_on_tenant_name"
  end

  create_table "sliders", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "image"
    t.integer "interval", default: 5000
    t.integer "language", default: 0, null: false
    t.integer "page", default: 0, null: false
    t.bigint "site_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["site_id"], name: "index_sliders_on_site_id"
  end

  create_table "speakers", force: :cascade do |t|
    t.string "avatar"
    t.datetime "created_at", precision: nil, null: false
    t.jsonb "description", default: {}
    t.jsonb "name", default: {}
    t.integer "order", default: 0
    t.bigint "site_id"
    t.string "slug"
    t.jsonb "title", default: {}
    t.datetime "updated_at", precision: nil, null: false
    t.index ["site_id", "slug"], name: "index_speakers_on_site_id_and_slug", unique: true
    t.index ["slug"], name: "index_speakers_on_slug", unique: true
  end

  create_table "sponsor_levels", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.jsonb "name", default: {}
    t.integer "order", default: 0
    t.bigint "site_id"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "sponsors", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.jsonb "description", default: {}
    t.bigint "level_id"
    t.string "logo"
    t.jsonb "name", default: {}
    t.integer "order", default: 0
    t.bigint "site_id"
    t.datetime "updated_at", precision: nil, null: false
    t.string "url"
    t.index ["level_id"], name: "index_sponsors_on_level_id"
    t.index ["site_id", "level_id"], name: "index_sponsors_on_site_id_and_level_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agenda_times", "agenda_days", column: "day_id"
  add_foreign_key "agendas", "agenda_times", column: "time_id"
  add_foreign_key "agendas", "rooms"
  add_foreign_key "agendas_speakers", "agendas"
  add_foreign_key "agendas_speakers", "speakers"
  add_foreign_key "partners", "partner_types", column: "type_id"
  add_foreign_key "sponsors", "sponsor_levels", column: "level_id"
end
