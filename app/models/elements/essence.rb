module Elements
  class Essence < ActiveRecord::Base
    self.abstract_class = true

    belongs_to :element,  :class_name => '::Elements::Element'
    belongs_to :property, :class_name => '::Elements::ElementProperty'
  end
end
