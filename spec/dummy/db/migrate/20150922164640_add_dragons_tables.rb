class AddDragonsTables < ActiveRecord::Migration
  def change
    create_table :dragons do |t|
      t.string :name
      t.string :color
      t.integer :size
      t.string :type
    end

    create_table :modern_dragon_attributes do |t|
      t.references :dragon
      t.string :twitter_followers
    end

    create_table :modern_dragon_jobs do |t|
      t.references :dragon
      t.string :position
      t.string :company_name
    end
    add_index :modern_dragon_jobs, :position, unique: true

    create_table :classic_dragon_attributes do |t|
      t.references :dragon
      t.integer :gold_count
      t.integer :piles_of_bones
    end
  end
end
