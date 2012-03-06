module Elements
  class ElementPropertyItem < ActiveRecord::Base
    belongs_to :property, :class_name => '::Elements::ElementProperty'

    validates :typename, 
      :uniqueness => { :scope => :property_id }, 
      :format     => { :with => /^[A-Z][a-zA-Z0-9]*$/ }

  end
end
