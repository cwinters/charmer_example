class CreateAttempts < ActiveRecord::Migration
  db_magic :connections => CharmerExample::Application.config.shards
  def change
    create_table :attempts do |t|
      t.integer :user_id
      t.integer :lesson_id
      t.boolean :correct
      t.text :response

      t.timestamps
    end
  end
end
