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

ActiveRecord::Schema.define(version: 2019_10_25_131207) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "admin_tasks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type", null: false
    t.uuid "created_by_id", null: false
    t.string "status", null: false
    t.jsonb "data", default: {}, null: false
    t.text "encrypted_data", null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text "error"
    t.string "lock_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_admin_tasks_on_created_by_id"
    t.index ["data"], name: "index_admin_tasks_on_data", using: :gin
    t.index ["type"], name: "index_admin_tasks_on_type"
  end

  create_table "allocations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "allocatable_type", null: false
    t.uuid "allocatable_id", null: false
    t.string "allocation_receivable_type", null: false
    t.uuid "allocation_receivable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allocatable_type", "allocatable_id", "allocation_receivable_type", "allocation_receivable_id"], name: "index_allocations_on_al_and_al_rec_unique", unique: true
    t.index ["allocatable_type", "allocatable_id"], name: "index_allocations_on_al_type_and_al_id"
    t.index ["allocation_receivable_type", "allocation_receivable_id"], name: "index_allocations_on_al_rec_type_and_al_rec_id"
  end

  create_table "audits", force: :cascade do |t|
    t.string "auditable_type"
    t.uuid "auditable_id"
    t.string "auditable_descriptor"
    t.string "associated_type"
    t.uuid "associated_id"
    t.string "associated_descriptor"
    t.string "user_type"
    t.uuid "user_id"
    t.string "username"
    t.string "user_email"
    t.string "action"
    t.jsonb "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at", null: false
    t.string "auditable_model_name"
    t.index ["associated_type", "associated_id"], name: "index_audits_on_associated_type_and_associated_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audits_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_email"], name: "index_audits_on_user_email"
    t.index ["user_type", "user_id"], name: "index_audits_on_user_type_and_user_id"
  end

  create_table "clusters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.uuid "crd_id", null: false
    t.uuid "created_by_id", null: false
    t.string "name", null: false
    t.string "status", null: false
    t.text "error"
    t.string "lock_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["crd_id"], name: "index_clusters_on_crd_id"
    t.index ["created_by_id"], name: "index_clusters_on_created_by_id"
    t.index ["name"], name: "index_clusters_on_name", unique: true
    t.index ["team_id"], name: "index_clusters_on_team_id"
  end

  create_table "crds", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "data", default: {}, null: false
    t.string "lock_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data"], name: "index_crds_on_data", using: :gin
  end

  create_table "credentials", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "integration_id", null: false
    t.string "owner_type", null: false
    t.uuid "owner_id", null: false
    t.string "kind", null: false
    t.string "name", null: false
    t.text "value", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_id"], name: "index_credentials_on_integration_id"
    t.index ["kind"], name: "index_credentials_on_kind"
    t.index ["name", "integration_id"], name: "index_credentials_on_name_and_integration_id", unique: true
    t.index ["owner_type", "owner_id"], name: "index_credentials_on_owner_type_and_owner_id"
  end

  create_table "hash_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "slug", null: false
    t.json "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_hash_records_on_slug", unique: true
  end

  create_table "identities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "integration_id", null: false
    t.string "external_id", null: false
    t.string "external_username"
    t.string "external_name"
    t.string "external_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "access_token"
    t.index ["integration_id", "external_id"], name: "index_identities_on_integration_id_and_external_id", unique: true
    t.index ["integration_id"], name: "index_identities_on_integration_id"
    t.index ["user_id", "integration_id"], name: "index_identities_on_user_id_and_integration_id", unique: true
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "integration_overrides", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "project_id", null: false
    t.uuid "integration_id", null: false
    t.text "config", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_id"], name: "index_integration_overrides_on_integration_id"
    t.index ["project_id", "integration_id"], name: "index_integration_overrides_on_project_id_and_integration_id", unique: true
    t.index ["project_id"], name: "index_integration_overrides_on_project_id"
  end

  create_table "integrations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "provider_id", null: false
    t.text "config", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "parent_ids", default: [], null: false, array: true
    t.index ["name"], name: "index_integrations_on_name", unique: true
    t.index ["provider_id"], name: "index_integrations_on_provider_id"
  end

  create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "team_id"
    t.index ["slug"], name: "index_projects_on_slug", unique: true
    t.index ["team_id"], name: "index_projects_on_team_id"
  end

  create_table "resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type", null: false
    t.uuid "project_id", null: false
    t.uuid "integration_id", null: false
    t.string "status", null: false
    t.string "name", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "lock_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "parent_id"
    t.uuid "requested_by_id"
    t.index ["integration_id"], name: "index_resources_on_integration_id"
    t.index ["name", "integration_id"], name: "index_resources_on_name_and_integration_id", unique: true
    t.index ["project_id"], name: "index_resources_on_project_id"
    t.index ["type"], name: "index_resources_on_type"
  end

  create_table "team_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.uuid "user_id", null: false
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "user_id"], name: "index_team_memberships_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_teams_on_slug", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.datetime "last_seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "user"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email"], name: "users_search_email_idx", opclass: :gin_trgm_ops, using: :gin
    t.index ["name"], name: "users_search_name_idx", opclass: :gin_trgm_ops, using: :gin
  end

  add_foreign_key "admin_tasks", "users", column: "created_by_id"
  add_foreign_key "clusters", "crds"
  add_foreign_key "clusters", "teams"
  add_foreign_key "clusters", "users", column: "created_by_id"
  add_foreign_key "integration_overrides", "integrations"
  add_foreign_key "integration_overrides", "projects"
  add_foreign_key "resources", "integrations"
  add_foreign_key "resources", "projects"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "team_memberships", "users"
end
