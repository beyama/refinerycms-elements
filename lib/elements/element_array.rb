module Elements
  class ElementArray

    UNASSIGNABLE_KEYS = %w( id _destroy type )

    instance_methods.each { |m| undef_method m unless m.to_s =~ /^(?:send|object_id)$|^__/ }

    attr_reader :element, :property, :property_id, :association_name, :sortable

    def initialize(element, property, options={})
      @element  = element
      @property = property
      @property_id = @property.is_a?(::Elements::ElementProperty) ? property.id : property

      options = { 
        :association_name => :element_associations,
        :sortable => true 
      }.update(options)

      @sortable = options[:sortable]
      @association_name = options[:association_name]

      reload
    end

    def reload
      @ary = association.to_a.select do |e| 
        e.property_id == @property_id
      end
      sort!
    end


    def build(attributes={}, &block)
      if attributes.is_a?(Array)
        attributes.map { |attr| build(attr) }
      else
        attributes.stringify_keys!

        type     = attributes.delete('type')
        position = (attributes.delete('position') || @ary.length).to_i

        if position > @ary.length
          position = @ary.length
        elsif position < 0
          position = 0
        end
      
        raise ArgumentError, 'Attribute `type` is required.' unless type

        klass = Elements::Types[type]
        raise Elements::TypeError, "Type `#{type}` not found." unless klass

        object = klass.new(attributes.except(*UNASSIGNABLE_KEYS).merge({
          :attachable  => element,
          :property_id => @property_id,
          :position    => @sortable ? position : nil
        }))

        raise Elements::TypeError, 'Type must be kind of Elements::Element.' \
          unless object.kind_of?(Elements::Element)

        yield object if block_given?

        @ary.insert(position, object)
        association.insert(position, object)

        object
      end
    end

    def create(attributes, &block)
      create_element(attributes, false, &block)
    end

    def create!(attributes, &block)
      create_element(attributes, true, &block)
    end

    def assign_attributes(attributes_collection)

      unless attributes_collection.is_a?(Hash) || attributes_collection.is_a?(Array)
        raise ArgumentError, "Hash or Array expected, got #{attributes_collection.class.name} (#{attributes_collection.inspect})"
      end


      if attributes_collection.is_a? Hash
        attributes_collection = if attributes_collection.has_key?('id') || attributes_collection.has_key?(:id)
          Array.wrap(attributes_collection)
        else
          attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes }
        end
      end

      existing_records = self.to_a

      attributes_collection.each do |attributes|
        attributes = attributes.with_indifferent_access

        if attributes['id'].blank?
          build(attributes)
        elsif existing_record = existing_records.detect { |record| record.id.to_s == attributes['id'].to_s }
          existing_record.attributes = attributes.except(*UNASSIGNABLE_KEYS)
          if attributes['_destroy'] && attributes['_destroy'].to_s =~ /true|1/
            existing_record.mark_for_destruction
            @ary.delete(existing_record)
          end
        else
          raise ActiveRecord::RecordNotFound, 
            "Couldn't find Element with ID=#{attributes['id']} for #{element.class.name} with ID=#{element.id}"
        end
      end

      @sortable ? reorder! : @ary.compact!
    end
    alias_method :attributes=, :assign_attributes
    
    def <<(element)
      element.position = @ary.length if @sortable
      element.attachable = element
      element.property_id = @property_id

      association << element
      @ary << element
    end

    def reorder!
      return unless @sortable
      sort!
      @ary.each_with_index do |element, i|
        element.position = i
      end
    end

    def sort!
      return unless @sortable
      @ary.compact!
      @ary.sort! {|a,b| (a.position || -1) <=> (b.position || -1) }
    end

    def to_a
      @ary.dup
    end

    protected

    def create_element(attributes, bang, &block)
      if block_given?
        build(attributes) do |element|
          yield element
          bang ? element.save! : element.save
        end
      else
        build(attributes) { |element| bang ? element.save! : element.save }
      end
    end

    def association
      element.send(@association_name)
    end

    def method_missing(sym, *args, &block)
      if @ary.respond_to?(sym)
        @ary.send(sym, *args, &block)
      else
        super
      end
    end

  end
end

