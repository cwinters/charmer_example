class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.text :login
      t.text :name
      t.integer :school_id

      t.timestamps
    end
  end
end
