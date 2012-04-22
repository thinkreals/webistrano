class RecipeDependency < ActiveRecord::Base
  belongs_to :recipe
  belongs_to :dependency, :class_name => "Recipe"
end
