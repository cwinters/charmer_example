class AddClassroomToAttemptAndLesson < ActiveRecord::Migration
  db_magic :connections => CharmerExample::Application.config.shards
  def change
    add_column :attempts, :classroom_id, :integer
    add_column :lessons, :classroom_id, :integer
  end
end
