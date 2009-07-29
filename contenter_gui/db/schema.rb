# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091231000000) do

  create_table "applications", :force => true do |t|
    t.integer  "lock_version",    :null => false
    t.string   "code"
    t.string   "name"
    t.string   "description"
    t.integer  "creator_user_id", :null => false
    t.integer  "updater_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "applications", ["code"], :name => "index_applications_on_code", :unique => true

  create_table "auth_changes", :force => true do |t|
    t.string   "user_id"
    t.time     "changed_at", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "brands", :force => true do |t|
    t.integer  "lock_version",    :null => false
    t.string   "code",            :null => false
    t.string   "name",            :null => false
    t.string   "description",     :null => false
    t.integer  "creator_user_id", :null => false
    t.integer  "updater_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "brands", ["code"], :name => "index_brands_on_code", :unique => true

  create_table "capabilities", :force => true do |t|
    t.integer  "lock_version", :null => false
    t.string   "name",         :null => false
    t.string   "description",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "capabilities", ["name"], :name => "index_capabilities_on_name", :unique => true

  create_table "content_key_versions", :force => true do |t|
    t.integer  "content_key_id"
    t.integer  "version"
    t.string   "uuid"
    t.string   "code"
    t.string   "name"
    t.string   "description"
    t.text     "data"
    t.integer  "content_type_id"
    t.integer  "creator_user_id"
    t.integer  "updater_user_id"
    t.datetime "updated_at"
    t.datetime "created_at",      :null => false
  end

  add_index "content_key_versions", ["content_key_id"], :name => "index_content_key_versions_on_content_key_id"
  add_index "content_key_versions", ["created_at"], :name => "index_content_key_versions_on_created_at"

  create_table "content_keys", :force => true do |t|
    t.integer  "version",         :null => false
    t.string   "uuid",            :null => false
    t.string   "code",            :null => false
    t.string   "name",            :null => false
    t.string   "description",     :null => false
    t.text     "data",            :null => false
    t.integer  "content_type_id", :null => false
    t.integer  "creator_user_id", :null => false
    t.integer  "updater_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_keys", ["code", "content_type_id"], :name => "index_content_keys_on_code_and_content_type_id", :unique => true
  add_index "content_keys", ["uuid"], :name => "index_content_keys_on_uuid", :unique => true

  create_table "content_types", :force => true do |t|
    t.integer  "lock_version",    :null => false
    t.string   "code",            :null => false
    t.string   "name",            :null => false
    t.string   "description",     :null => false
    t.string   "key_regexp",      :null => false
    t.integer  "creator_user_id", :null => false
    t.integer  "updater_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_types", ["code"], :name => "index_content_types_on_code", :unique => true

  create_table "content_versions", :force => true do |t|
    t.integer  "content_id"
    t.integer  "version"
    t.string   "uuid"
    t.integer  "content_key_id"
    t.integer  "language_id"
    t.integer  "country_id"
    t.integer  "brand_id"
    t.integer  "application_id"
    t.integer  "mime_type_id"
    t.string   "md5sum"
    t.binary   "data"
    t.integer  "creator_user_id"
    t.integer  "updater_user_id"
    t.datetime "updated_at"
    t.datetime "created_at",      :null => false
  end

  add_index "content_versions", ["application_id"], :name => "index_content_versions_on_application_id"
  add_index "content_versions", ["brand_id"], :name => "index_content_versions_on_brand_id"
  add_index "content_versions", ["content_id"], :name => "index_content_versions_on_content_id"
  add_index "content_versions", ["content_key_id"], :name => "index_content_versions_on_content_key_id"
  add_index "content_versions", ["country_id"], :name => "index_content_versions_on_country_id"
  add_index "content_versions", ["created_at"], :name => "index_content_versions_on_created_at"
  add_index "content_versions", ["language_id"], :name => "index_content_versions_on_language_id"
  add_index "content_versions", ["md5sum"], :name => "index_content_versions_on_md5sum"
  add_index "content_versions", ["mime_type_id"], :name => "index_content_versions_on_mime_type_id"
  add_index "content_versions", ["uuid"], :name => "index_content_versions_on_uuid"

  create_table "contents", :force => true do |t|
    t.string   "uuid",            :null => false
    t.integer  "content_key_id",  :null => false
    t.integer  "language_id",     :null => false
    t.integer  "country_id",      :null => false
    t.integer  "brand_id",        :null => false
    t.integer  "application_id",  :null => false
    t.integer  "mime_type_id",    :null => false
    t.string   "md5sum",          :null => false
    t.binary   "data",            :null => false
    t.integer  "creator_user_id", :null => false
    t.integer  "updater_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "version"
  end

  add_index "contents", ["application_id", "brand_id", "content_key_id", "country_id", "language_id", "mime_type_id"], :name => "contents_u", :unique => true
  add_index "contents", ["application_id"], :name => "index_contents_on_application_id"
  add_index "contents", ["brand_id"], :name => "index_contents_on_brand_id"
  add_index "contents", ["content_key_id"], :name => "index_contents_on_content_key_id"
  add_index "contents", ["country_id"], :name => "index_contents_on_country_id"
  add_index "contents", ["language_id"], :name => "index_contents_on_language_id"
  add_index "contents", ["md5sum"], :name => "index_contents_on_md5sum"
  add_index "contents", ["mime_type_id"], :name => "index_contents_on_mime_type_id"
  add_index "contents", ["uuid"], :name => "index_contents_on_uuid", :unique => true

  create_table "countries", :force => true do |t|
    t.integer  "lock_version",    :null => false
    t.string   "code",            :null => false
    t.string   "name",            :null => false
    t.string   "description",     :null => false
    t.integer  "creator_user_id", :null => false
    t.integer  "updater_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "countries", ["code"], :name => "index_countries_on_code", :unique => true

  create_table "languages", :force => true do |t|
    t.integer  "lock_version",    :null => false
    t.string   "code",            :null => false
    t.string   "name",            :null => false
    t.string   "description",     :null => false
    t.integer  "creator_user_id", :null => false
    t.integer  "updater_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "languages", ["code"], :name => "index_languages_on_code", :unique => true

  create_table "mime_types", :force => true do |t|
    t.integer  "lock_version",    :null => false
    t.string   "code",            :null => false
    t.string   "name",            :null => false
    t.string   "description",     :null => false
    t.integer  "creator_user_id", :null => false
    t.integer  "updater_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mime_types", ["code"], :name => "index_mime_types_on_code", :unique => true

  create_table "role_capabilities", :force => true do |t|
    t.integer  "lock_version",  :null => false
    t.integer  "role_id",       :null => false
    t.integer  "capability_id", :null => false
    t.boolean  "allow",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "role_capabilities", ["capability_id", "role_id"], :name => "index_role_capabilities_on_role_id_and_capability_id", :unique => true
  add_index "role_capabilities", ["capability_id"], :name => "index_role_capabilities_on_capability_id"
  add_index "role_capabilities", ["role_id"], :name => "index_role_capabilities_on_role_id"

  create_table "roles", :force => true do |t|
    t.integer  "lock_version", :null => false
    t.string   "name",         :null => false
    t.string   "description",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name"], :name => "index_roles_on_name", :unique => true

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id", :null => false
    t.integer "user_id", :null => false
  end

  add_index "roles_users", ["role_id", "user_id"], :name => "index_roles_users_on_role_id_and_user_id", :unique => true
  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"
  add_index "sessions", ["user_id"], :name => "index_sessions_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 40,                  :null => false
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "email",                     :limit => 100,                 :null => false
    t.string   "crypted_password",          :limit => 40,                  :null => false
    t.string   "salt",                      :limit => 40,                  :null => false
    t.datetime "created_at",                                               :null => false
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

  create_table "version_list_content_keys", :force => true do |t|
    t.integer "version_list_id",        :null => false
    t.integer "content_key_version_id", :null => false
  end

  add_index "version_list_content_keys", ["content_key_version_id", "version_list_id"], :name => "version_list_key_u", :unique => true
  add_index "version_list_content_keys", ["content_key_version_id"], :name => "index_version_list_content_keys_on_content_key_version_id"
  add_index "version_list_content_keys", ["version_list_id"], :name => "index_version_list_content_keys_on_version_list_id"

  create_table "version_list_contents", :force => true do |t|
    t.integer "version_list_id",    :null => false
    t.integer "content_version_id", :null => false
  end

  add_index "version_list_contents", ["content_version_id", "version_list_id"], :name => "version_list_u", :unique => true
  add_index "version_list_contents", ["content_version_id"], :name => "index_version_list_contents_on_content_version_id"
  add_index "version_list_contents", ["version_list_id"], :name => "index_version_list_contents_on_version_list_id"

  create_table "version_list_name_versions", :force => true do |t|
    t.integer  "version_list_name_id"
    t.integer  "version"
    t.string   "name"
    t.string   "description"
    t.integer  "version_list_id"
    t.integer  "creator_user_id"
    t.integer  "updater_user_id"
    t.datetime "updated_at"
  end

  add_index "version_list_name_versions", ["version_list_name_id"], :name => "index_version_list_name_versions_on_version_list_name_id"

  create_table "version_list_names", :force => true do |t|
    t.string   "name",            :null => false
    t.string   "description",     :null => false
    t.integer  "version_list_id"
    t.integer  "creator_user_id", :null => false
    t.integer  "updater_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "version"
  end

  add_index "version_list_names", ["name"], :name => "index_version_list_names_on_name", :unique => true
  add_index "version_list_names", ["version_list_id"], :name => "index_version_list_names_on_version_list_id"

  create_table "version_lists", :force => true do |t|
    t.integer  "lock_version",    :null => false
    t.string   "comment",         :null => false
    t.datetime "point_in_time"
    t.integer  "creator_user_id", :null => false
    t.integer  "updater_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "version_lists", ["point_in_time"], :name => "index_version_lists_on_point_in_time"

end
