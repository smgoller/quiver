class CreatePoniesTable < ActiveRecord::Migration
  def change
    create_table :ponies do |t|
      t.string :name
      t.string :color
      t.integer :mane_length
      t.boolean :unicorn
      t.boolean :pegasus
      t.integer :reputation, default: 0

      t.integer :mentor_id
    end
  end
end
