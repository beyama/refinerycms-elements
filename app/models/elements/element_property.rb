module Elements
  class ElementProperty < ActiveRecord::Base

    INVALID_NAME_PATTERN = /(?:_id|_attributes|_type|\?|\!|\=)$/

    ELEMENT_METHODS = ActiveRecord::Base.instance_methods + 
      Elements::ElementMethods::InstanceMethods.instance_methods

    NAME_BLACKLIST = \
      ELEMENT_METHODS.uniq.map(&:to_s).reject {|name| name =~ INVALID_NAME_PATTERN } +
      # Keywords
      %w(and def end in or self	unless begin defined? ensure module	redo super until break do 
         false next rescue then when case else for nil retry true while alias class elsif if 
         not return undef yield) +
      # Reserved names
      %w(id type typename)

    acts_as_list :scope => :descriptor

    serialize :enum, Array

    belongs_to :descriptor, :class_name => '::Elements::ElementDescriptor'

    has_many :items, :class_name => '::Elements::ElementPropertyItem', 
      :foreign_key => :property_id, :order => 'position ASC', :dependent => :destroy

    validates :name, 
      :uniqueness => { :scope => :descriptor_id }, 
      :exclusion  => { :in => NAME_BLACKLIST },
      :format     => { :with => /^[a-z][a-z0-9_]*$/ }

    validates :name, :format => { :without => INVALID_NAME_PATTERN }

    validates :typename, :presence => true, :format => { :with => /^[A-Z][a-zA-Z0-9]*$/ }

    def klass
      if essence?
        ::Elements::Types::ESSENCES[self.typename].constantize
      else
        ::Elements::Types::const(self.typename)
      end
    end

    def essence?
      ::Elements::Types::ESSENCES.has_key?(self.typename)
    end
    alias_method :essence, :essence?

    def element?
      self.typename.present? && !self.essence?
    end

    def array?
      self.typename == 'Array'
    end
    alias_method :array, :array?

    def <=>(other)
      self.position <=> other.position
    end

  end
end
