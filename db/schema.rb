# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_01_02_143315) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_admin_users_on_unlock_token", unique: true
  end

  create_table "agenda_days", force: :cascade do |t|
    t.string "label"
    t.date "date", default: -> { "now()" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "agenda_tags", force: :cascade do |t|
    t.jsonb "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "agenda_times", force: :cascade do |t|
    t.string "label"
    t.integer "order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "day_id"
    t.boolean "single"
    t.index ["day_id"], name: "index_agenda_times_on_day_id"
  end

  create_table "agendas", force: :cascade do |t|
    t.jsonb "subject", default: {}
    t.jsonb "description", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "time_id"
    t.bigint "room_id"
    t.integer "order", default: 0, null: false
    t.integer "language"
    t.integer "translated_language"
    t.integer "translated_type"
    t.string "begin_at"
    t.string "end_at"
    t.index ["room_id"], name: "index_agendas_on_room_id"
    t.index ["time_id"], name: "index_agendas_on_time_id"
  end

  create_table "agendas_speakers", force: :cascade do |t|
    t.bigint "agenda_id"
    t.bigint "speaker_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agenda_id"], name: "index_agendas_speakers_on_agenda_id"
    t.index ["speaker_id"], name: "index_agendas_speakers_on_speaker_id"
  end

  create_table "agendas_taggings", force: :cascade do |t|
    t.bigint "agenda_id"
    t.bigint "agenda_tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "games", force: :cascade do |t|
    t.jsonb "name", null: false
    t.jsonb "description", null: false
    t.jsonb "team", null: false
    t.string "video"
    t.string "thumbnail"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "website"
    t.integer "order", default: 0
  end

  create_table "news", force: :cascade do |t|
    t.jsonb "title", default: {}
    t.jsonb "content", default: {}
    t.string "author_type"
    t.bigint "author_id"
    t.string "slug", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "thumbnail"
    t.index ["author_type", "author_id"], name: "index_news_on_author_type_and_author_id"
    t.index ["slug"], name: "index_news_on_slug", unique: true
    t.index ["status"], name: "index_news_on_status"
  end

  create_table "partner_types", force: :cascade do |t|
    t.jsonb "name", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order", default: 0
  end

  create_table "partners", force: :cascade do |t|
    t.jsonb "name", default: {}
    t.string "logo"
    t.bigint "type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.integer "order", default: 0
    t.jsonb "description"
    t.index ["type_id"], name: "index_partners_on_type_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.integer "order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sites", force: :cascade do |t|
    t.string "domain", null: false
    t.jsonb "name", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tenant_name"
    t.jsonb "description", default: {}
    t.string "logo"
    t.jsonb "options"
    t.string "figure"
    t.jsonb "indie_space_description"
    t.index ["domain"], name: "index_sites_on_domain"
    t.index ["tenant_name"], name: "index_sites_on_tenant_name"
  end

  create_table "sliders", force: :cascade do |t|
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "language", default: 0, null: false
    t.integer "page", default: 0, null: false
    t.integer "interval", default: 5000
  end

  create_table "speakers", force: :cascade do |t|
    t.jsonb "name", default: {}
    t.jsonb "description", default: {}
    t.string "avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "title"
    t.integer "order", default: 0
  end

  create_table "sponsor_levels", force: :cascade do |t|
    t.jsonb "name", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order", default: 0
  end

  create_table "sponsors", force: :cascade do |t|
    t.jsonb "name", default: {}
    t.string "logo"
    t.string "url"
    t.bigint "level_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order", default: 0
    t.jsonb "description"
    t.index ["level_id"], name: "index_sponsors_on_level_id"
  end

  add_foreign_key "agenda_times", "agenda_days", column: "day_id"
  add_foreign_key "agendas", "agenda_times", column: "time_id"
  add_foreign_key "agendas", "rooms"
  add_foreign_key "agendas_speakers", "agendas"
  add_foreign_key "agendas_speakers", "speakers"
  add_foreign_key "partners", "partner_types", column: "type_id"
  add_foreign_key "sponsors", "sponsor_levels", column: "level_id"
end
