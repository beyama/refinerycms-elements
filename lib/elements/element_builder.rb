module Elements
  class ElementBuilder
    class InvalidProperty < StandardError; end
    class PropertyNotFound < StandardError; end
    class DescriptorNotFound < StandardError; end
    class ParentNotFound < StandardError; end

    class PropertyBuilder
      attr_reader :property
      def initialize(property)
        @property = property
      end

      %w(title description required pattern minimum maximum default enum widget).each do |attr|
        class_eval <<-end_eval, __FILE__, __LINE__
          def #{attr}(value)
            @property.#{attr} = value
          end
        end_eval
      end

      def items(*items)
        items.flatten!
        items.each_with_index do |type, i| 
          @property.items.build(:typename => type.to_s.camelcase, :position => i) 
        end
      end
    end

    class << self

      def table_exists?
        ::Elements::Element.table_exists?
      end

      def create(name, attributes={}, &block)
        return unless self.table_exists?
        attributes.update(:name => name.to_s.camelcase)
        descriptor = Elements::ElementDescriptor.create!(attributes)
        self.update_descriptor(descriptor, &block)
      end

      def update(name, attributes={}, &block)
        return unless self.table_exists?
        name = name.to_s.camelcase
        descriptor = Elements::ElementDescriptor.find_by_name(name)

        raise DescriptorNotFound, "Descriptor `#{name}` not found." unless descriptor

        descriptor.attributes = attributes if attributes.present?
        self.update_descriptor(descriptor, &block)
      end

      def create_or_update(name, attributes={}, &block)
        return unless self.table_exists?
        descriptor = Elements::ElementDescriptor.find_by_name(name.to_s.camelcase)
        descriptor ? self.update(name, attributes, &block) : self.create(name, attributes, &block)
      end

      protected
      def update_descriptor(descriptor, &block)
        builder = new(descriptor, &block)
        descriptor.save!
        descriptor
      end

    end

    attr_reader :descriptor

    def initialize(descriptor, &block)
      @descriptor = descriptor
      yield self if block_given?
    end

    %w(title description parent_id).each do |attr|
      class_eval <<-end_eval, __FILE__, __LINE__
        def #{attr}(value)
          @descriptor.#{attr} = value
        end
      end_eval
    end

    def parent(name_or_descriptor)
      if name_or_descriptor.is_a?(Elements::ElementDescriptor)
        @descriptor.parent = name_or_descriptor
      else
        name = name_or_descriptor.to_s.camelcase
        parent = Elements::ElementDescriptor.find_by_name(name)
        raise ParentNotFound, "Parent `#{name}` not found." unless parent
        @descriptor.parent = parent
      end
    end

    Elements::Types::ESSENCES.each_pair do |typename, _|
      class_eval <<-end_eval, __FILE__, __LINE__
        def #{typename.underscore}(name, attributes={}, &block)
          self.property(name, "#{typename}", attributes, &block)
        end
      end_eval
    end

    def color(name, attributes={}, &block)
      attributes = attributes.merge(:minimum => 7, :maximum => 7, :widget => 'EssenceColorView')
      self.text(name, attributes, &block)
    end

    def property(name, typename, attributes={})
      attributes.update(:name => name.to_s, :typename => typename.to_s.camelcase)

      after = attributes.delete(:after)
      before = attributes.delete(:before)
      sibling_name = (after || before).to_s

      attributes[:position] = @descriptor.properties.size

      if (property = find_property(attributes[:name]))
        property.attributes = attributes
      else
        property = @descriptor.properties.create!(attributes)
      end

      if (after || before) && (sibling = find_property(sibling_name))
        property.insert_at(after ? sibling.position + 1 : sibling.position)
      end

      if block_given?
        yield PropertyBuilder.new(property) 
        raise InvalidProperty, property.errors.full_messages.first unless property.valid?
        property.save
      end

      property
    end
    alias_method :element, :property

    def array(name, attributes={}, &block)
      items = attributes.delete(:items)
      property = self.property(name, 'Array', attributes, &block)
      if items.present? 
        PropertyBuilder.new(property).items(items) 
        property.save
      end
      property
    end

    def rename_property(old_name, new_name)
      new_name = new_name.to_s
      property = find_property(old_name, true)
      property.update_attribute(:name, new_name)
    end

    def remove_property(name)
      property = find_property(name, true)

      klass = property.essence? ? property.klass : Elements::Element
      klass.destroy_all(:property_id => property.id)

      property.destroy
    end

    def property_exists?(name)
      !!find_property(name)
    end

    def find_property(name, raise_unless_exists=false)
      name = name.to_s
      property = @descriptor.properties.to_a.find {|p| p.name == name }
      raise PropertyNotFound, "Property `#{name}` not found." if property.nil? && raise_unless_exists
      property
    end

  end
end
