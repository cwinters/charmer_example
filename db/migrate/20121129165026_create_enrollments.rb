class CreateEnrollments < ActiveRecord::Migration
  db_magic :connections => CharmerExample::Application.config.shards
  def change
    create_table :enrollments do |t|
      t.integer :user_id
      t.integer :classroom_id

      t.timestamps
    end
  end
end
