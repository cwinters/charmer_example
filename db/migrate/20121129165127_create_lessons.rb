class CreateLessons < ActiveRecord::Migration
  db_magic :connections => CharmerExample::Application.config.shards
  def change
    create_table :lessons do |t|
      t.integer :enrollment_id
      t.string :name

      t.timestamps
    end
  end
end
