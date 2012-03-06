module Elements
  class ElementDescriptor < ActiveRecord::Base

    self.include_root_in_json = false

    belongs_to :parent, :class_name => '::Elements::ElementDescriptor'

    has_many :properties, :class_name => '::Elements::ElementProperty', 
      :foreign_key => :descriptor_id, :order => 'position ASC', :dependent => :destroy

    validates :name, 
      :uniqueness => true, 
      :exclusion  => { :in => Elements::Types::BUILT_IN.keys },
      :format     => { :with => /^[A-Z][a-zA-Z0-9]*$/ }

    def as_json(options)
      options ||= {}
      options[:only] ||= [:name, :title, :description]
      options[:include] ||= {
        :parent => { :only => :name },
        :properties => {
          :only => [ :name, :title, :description, :typename, :enum, :required, 
                     :pattern, :minimum, :maximum, :default, :widget ],
          :methods => [:essence, :array],
          :include => { :items => { :only => [ :typename, :position ] } }
        } 
      }
      super(options)
    end

  end
end
