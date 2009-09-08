ActiveRecord::Schema.define do

  create_table "users", :force => true do |t|
    t.column "name",       :text
    t.column "salary",     :integer,  :default => 70000
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "user_type",       :text
  end

  create_table "posts", :force => true do |t|
    t.column "user_id",    :integer
    t.column "title",      :text
    t.column "body",       :text
  end
end
