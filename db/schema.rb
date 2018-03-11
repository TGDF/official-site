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

ActiveRecord::Schema.define(version: 20180311090551) do

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

  create_table "agenda_translations", force: :cascade do |t|
    t.integer "agenda_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subject"
    t.text "description"
    t.index ["agenda_id"], name: "index_agenda_translations_on_agenda_id"
    t.index ["locale"], name: "index_agenda_translations_on_locale"
  end

  create_table "agendas", force: :cascade do |t|
    t.string "subject"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "news", force: :cascade do |t|
    t.string "title"
    t.text "content"
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

  create_table "news_translations", force: :cascade do |t|
    t.integer "news_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.text "content"
    t.index ["locale"], name: "index_news_translations_on_locale"
    t.index ["news_id"], name: "index_news_translations_on_news_id"
  end

  create_table "partner_translations", force: :cascade do |t|
    t.integer "partner_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["locale"], name: "index_partner_translations_on_locale"
    t.index ["partner_id"], name: "index_partner_translations_on_partner_id"
  end

  create_table "partner_type_translations", force: :cascade do |t|
    t.integer "partner_type_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["locale"], name: "index_partner_type_translations_on_locale"
    t.index ["partner_type_id"], name: "index_partner_type_translations_on_partner_type_id"
  end

  create_table "partner_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "partners", force: :cascade do |t|
    t.string "name"
    t.string "logo"
    t.bigint "type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["type_id"], name: "index_partners_on_type_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "domain", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tenant_name"
    t.index ["domain"], name: "index_sites_on_domain"
    t.index ["tenant_name"], name: "index_sites_on_tenant_name"
  end

  create_table "speaker_translations", force: :cascade do |t|
    t.integer "speaker_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.text "description"
    t.index ["locale"], name: "index_speaker_translations_on_locale"
    t.index ["speaker_id"], name: "index_speaker_translations_on_speaker_id"
  end

  create_table "speakers", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sponsor_level_translations", force: :cascade do |t|
    t.integer "sponsor_level_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["locale"], name: "index_sponsor_level_translations_on_locale"
    t.index ["sponsor_level_id"], name: "index_sponsor_level_translations_on_sponsor_level_id"
  end

  create_table "sponsor_levels", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sponsor_translations", force: :cascade do |t|
    t.integer "sponsor_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["locale"], name: "index_sponsor_translations_on_locale"
    t.index ["sponsor_id"], name: "index_sponsor_translations_on_sponsor_id"
  end

  create_table "sponsors", force: :cascade do |t|
    t.string "name"
    t.string "logo"
    t.string "url"
    t.bigint "level_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["level_id"], name: "index_sponsors_on_level_id"
  end

  add_foreign_key "partners", "partner_types", column: "type_id"
  add_foreign_key "sponsors", "sponsor_levels", column: "level_id"
end
