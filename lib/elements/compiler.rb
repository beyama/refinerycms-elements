module Elements
  class Compiler
    attr_reader :descriptor, :klass

    def initialize(descriptor)
      @descriptor = descriptor
      @compiled   = false

      if @descriptor.parent.nil?
        @extends = Elements::Element
      else
        @extends = Elements::Types.const(@descriptor.parent.name)

        if @extends.nil?
          compiler = self.class.new(@descriptor.parent)
          @extends = compiler.compile
        end
      end

      @klass = Class.new(@extends)
      @klass.descriptor = @descriptor
    end

    def compile
      return klass if @compiled

      orig = Elements::Types[@descriptor.name]

      begin
        properties = self.klass.own_properties = {}
        @descriptor.properties.each do |p| 
          compile_property(p)
          properties[p.id] = p
        end
        self.klass.ancestors_and_own_properties = (@extends.ancestors_and_own_properties || []) + properties.values.sort

        Elements::Types[@descriptor.name] = @klass
      rescue => e
        Elements::Types[@descriptor.name] = orig
        raise e
      end

      klass
    end

    private

    def compile_property(property)
      name     = property.name
      type     = property.typename
      required = property.required
      min      = property.minimum
      max      = property.maximum
      pattern  = property.pattern
      enum     = property.enum

      if property.essence?
        delegate_reader(property, name, 'value')
        delegate_writer(property, name, 'value')
        if %w(Image Resource Any).include?(type)
          delegate_reader(property, "#{name}_id", 'value_id')
          delegate_writer(property, "#{name}_id", 'value_id')

          if type == 'Any'
            delegate_reader(property, "#{name}_type", 'value_type')
            delegate_writer(property, "#{name}_type", 'value_type')
          end
        end
      elsif property.array?
        element_reader(property)
        element_attributes_writer(property)
      else
        element_reader(property)
        element_writer(property)
        element_attributes_reader(property)
        element_attributes_writer(property)
      end

      # Validation
      if required
        @klass.validates_presence_of(name)
      end

      if type == 'Integer' || type == 'Float'
        options = {}
        options[:only_integer] = type == 'Integer'
        options[:greater_than_or_equal_to] = min if min
        options[:less_than_or_equal_to]    = max if max
        options[:allow_nil] = true unless required
        
        @klass.validates_numericality_of(name, options)

        if enum.present?
          options = {}
          options[:in] = enum
          options[:allow_nil] = true unless required

          @klass.validates_inclusion_of(name, options) 
        end

      elsif type == 'Text'
        if min || max
          options = {}
          options[:minimum] = min.to_i if min
          options[:maximum] = max.to_i if max
          options[:allow_blank] = options[:allow_nil] = true unless required
          
          @klass.validates_length_of(name, options)
        end

        if pattern.present?
          options = {}
          options[:with] = Regexp.new(pattern)
          options[:allow_blank] = options[:allow_nil] = true unless required

          @klass.validates_format_of(name, options)
        end

        if enum.present?
          options = {}
          options[:in] = enum
          options[:allow_blank] = options[:allow_nil] = true unless required

          @klass.validates_inclusion_of(name, options) 
        end

      end
    end

    def element_reader(property)
      @klass.instance_eval do

        define_method(property.name) do
          self.read_property(property)
        end

      end
    end

    def element_writer(property)
      @klass.instance_eval do

        define_method("#{property.name}=") do |value|
          self.write_property(property, value)
        end

      end
    end

    def delegate_writer(property, from, to)
      @klass.instance_eval do

        define_method("#{from}=") do |value|
          # strip value
          if value.respond_to?(:strip)
            value = (value.blank?) ? nil : value.strip
          end

          object = self.read_property(property)
          if object
            object.send("#{to}=", value)
          elsif value
            object = Elements::Types.const(property.typename).new(:property => property, to => value)
            self.write_property(property, object)
            value
          end
        end

      end
    end

    def delegate_reader(property, from, to)
      @klass.instance_eval do
        
        define_method(from) do
          object = self.read_property(property)
          object ? object.send(to) : nil
        end

      end
    end
    
    def element_attributes_reader(property)
      delegate_reader(property, "#{property.name}_attributes", "attributes")
    end

    def element_attributes_writer(property)
      delegate_writer(property, "#{property.name}_attributes", "attributes")
    end

  end
end
