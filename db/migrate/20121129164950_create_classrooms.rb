class CreateClassrooms < ActiveRecord::Migration
  def change
    create_table :classrooms do |t|
      t.text :name
      t.integer :school_id

      t.timestamps
    end
  end
end
