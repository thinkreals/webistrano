class Recipe < ActiveRecord::Base
  has_and_belongs_to_many :stages
  has_many :recipe_dependencies
  has_many :dependencies, :through => :recipe_dependencies
  has_many :inverse_recipe_dependencies, :class_name => "RecipeDependency", :foreign_key => "dependency_id"
  has_many :inverse_dependencies, :through => :inverse_recipe_dependencies, :source => :recipe
  
  validates_uniqueness_of :name
  validates_presence_of :name, :body
  validates_length_of :name, :maximum => 250

  attr_accessible :name, :body, :description
  
  named_scope :ordered, :order => "name ASC"
  
  version_fu rescue nil # hack to silence migration errors when the original table is not there
  
  def validate
    check_syntax
  end

  def all_dependencies
    @all_dependencies ||= self.class.all_dependencies(self)
  end

  def all_inverse_dependencies
    @all_inverse_dependencies ||= self.class.all_inverse_dependencies(self)
  end

  def all_stages
    @all_stages ||= self.stages + self.all_inverse_dependencies.collect{|r| r.stages}.flatten
  end

  def depend_on?(recipe)
    self.all_dependencies.include?(recipe)
  end
 
  def check_syntax
   return if self.body.blank?

   result = ""
   Open4::popen4 "ruby -wc" do |pid, stdin, stdout, stderr|
     stdin.write body
     stdin.close
     output = stdout.read
     errors = stderr.read
     result = output.empty? ? errors : output
   end
   
   unless result == "Syntax OK"
     line = $1.to_i if result =~ /^-:(\d+):/
     errors.add(:body, "syntax error at line: #{line}") unless line.nil?
   end
  rescue => e
    RAILS_DEFAULT_LOGGER.error "Error while validating recipe syntax of recipe #{self.id}: #{e.inspect} - #{e.backtrace.join("\n")}"
  end
 
  class << self
    def all_recipes(recipes, inverse = false, recipe_bucket = nil)
      recipe_bucket = recipes if recipe_bucket.nil?
      d = recipe_bucket.collect{ |r|
        inverse ? r.inverse_dependencies : r.dependencies
      }.flatten.uniq
      d = d - recipes
      return recipes if d.empty?
      recipes += d
      return all_recipes(recipes, inverse, d)
    end

    def all_dependencies(*recipes)
      recipes = recipes[0] if recipes[0].is_a? Array
      self.all_recipes(recipes) - recipes
    end

    def all_inverse_dependencies(*recipes)
      recipes = recipes[0] if recipes[0].is_a? Array
      self.all_recipes(recipes, true) - recipes
    end
  end
end
