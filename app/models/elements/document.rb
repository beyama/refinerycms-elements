module Elements
  class Document < ActiveRecord::Base
    acts_as_nested_set :dependent => :destroy  

    include ::Elements::HasManyElements
    alias_method :title, :element_title
    alias_method :translation, :element_translation

    def locales
      self.elements.collect(&:locale).uniq
    end
  end
end
