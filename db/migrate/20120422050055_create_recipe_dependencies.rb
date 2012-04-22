class CreateRecipeDependencies < ActiveRecord::Migration
  def self.up
    create_table :recipe_dependencies do |t|
      t.references :recipe
      t.integer :dependency_id
      t.timestamps
    end

    add_index :recipe_dependencies, :recipe_id
    add_index :recipe_dependencies, :dependency_id
  end

  def self.down
    drop_table :recipe_dependencies
  end
end
