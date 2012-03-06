module Elements
  class Element < ActiveRecord::Base
    include ::Elements::ElementMethods
  end
end

# Load all elements
::Elements::Types.reload! if ::Elements::Element.table_exists?
