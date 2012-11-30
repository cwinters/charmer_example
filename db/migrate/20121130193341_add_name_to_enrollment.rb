class AddNameToEnrollment < ActiveRecord::Migration
  db_magic :connections => CharmerExample::Application.config.shards
  def change
    add_column :enrollments, :name, :string
  end
end
