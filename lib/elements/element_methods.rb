module Elements
  module ElementMethods
    extend ActiveSupport::Concern

    included do
      class_attribute :descriptor, :own_properties, :ancestors_and_own_properties

      self.include_root_in_json = false

      ESSENCE_ASSOCIATIONS = Hash.new

      belongs_to :property, :class_name => '::Elements::ElementProperty'
      belongs_to :attachable, :polymorphic => true

      Elements::Types::ESSENCES.each_pair do |type, klass|
        ESSENCE_ASSOCIATIONS[type] = "#{type.underscore}_associations".intern
        has_many ESSENCE_ASSOCIATIONS[type], :class_name => klass, :dependent => :destroy, :autosave => true
      end

      has_many :element_associations, 
        :class_name => '::Elements::Element', :as => :attachable, :dependent => :destroy, :autosave => true

      scope :with_locale, proc {|locale| where(:locale => locale.to_s) }

      after_initialize :set_defaults
    end

    module ClassMethods

      # Remove all autogenrated subclasses before class reload
      def before_remove_const
        super
        ::Elements::Types.reset! if self.table_exists?
      end

      def association_name_for_property(property)
        ESSENCE_ASSOCIATIONS.has_key?(property.typename) ? 
          ESSENCE_ASSOCIATIONS[property.typename] : 
          :element_associations
      end

      def has_property?(name)
        !!self.property(name)
      end

      def property(name)
        name = name.to_s
        @_property_by_name ||= Hash.new
        @_property_by_name[name] ||= self.ancestors_and_own_properties.find{|prop| prop.name == name }
      end

    end # ClassMethods

    def has_property?(name)
      self.class.has_property?(name)
    end

    def association_for_property(property)
      self.send(self.class.association_name_for_property(property))
    end

    def properties
      @properties ||= {}
    end

    def reload(*args)
      @properties = nil
      super(*args)
    end

    def serializable_hash(options = nil)
      hash = { 
        'id' => self.id,
        'typename' => self.class.name.demodulize,
        'locale' => self.locale
      }

      self.ancestors_and_own_properties.each do |property|
        next unless value = read_property(property)

        if property.essence?
          if %w(Image Resource Any).include?(property.typename)
            hash[property.name] = value.serializable_hash
          else
            hash[property.name] = value.value
          end
        elsif property.array?
          hash[property.name] = value.map(&:serializable_hash)
        else
          hash[property.name] = value.serializable_hash
        end
      end

      hash
    end

    def read_property(property)
      id = property.id
      properties[id] ||= begin
        if property.array?
          Elements::ElementArray.new(self, property)
        else
          self.association_for_property(property).to_ary.find {|o| o.property_id == id }
        end
      end
    end

    def write_property(property, value)
      old_value   = read_property(property)
      association = association_for_property(property)

      if old_value
        if old_value != value
          association.delete(old_value) 
        else
          return old_value
        end
      end

      properties[property.id] = value
      if value
        value.property_id = property.id
        if value.kind_of?(Elements::Element)
          value.attachable = self 
        end
        association << value 
      end
      value
    end

    def set_defaults
      return unless self.ancestors_and_own_properties

      self.class.ancestors_and_own_properties.each do |property|
        if property.essence? && property.default.present? && property.typename != 'Any'
          if self.send(property.name).blank?
            value = nil
            case property.typename
            when 'Image' 
              value = ::Refinery::Image.find_by_id(property.default)
            when 'Resource' 
              value = ::Refinery::Resource.find_by_id(property.default)
            else 
              value = property.default
            end

            self.send("#{property.name}=", value) if value
          end
        end
      end
    end

  end
end
