module Elements
  module Types
    ESSENCES = {
      'Text'     => '::Elements::EssenceText',
      'Integer'  => '::Elements::EssenceInteger',
      'Float'    => '::Elements::EssenceFloat',
      'Date'     => '::Elements::EssenceDate',
      'Datetime' => '::Elements::EssenceDatetime',
      'Boolean'  => '::Elements::EssenceBoolean',
      'Image'    => '::Elements::EssenceImage',
      'Resource' => '::Elements::EssenceResource',
      'Any'      => '::Elements::EssenceAny',
    }

    BUILT_IN = ESSENCES.dup
    BUILT_IN['Element'] = '::Elements::Element'

    extend self

    def const(name)
      name = name.to_s
      if BUILT_IN.has_key?(name)
        BUILT_IN[name].constantize
      else
        const_defined?(name) ? const_get(name) : nil
      end
    end
    alias_method :[], :const

    def add_klass(name, klass)
      @constants ||= []
      remove_klass(name)
      const_set(name, klass)
      @constants << name.to_s
    end
    alias_method :[]=, :add_klass

    def remove_klass(name)
      return unless @constants
      if @constants.include?(name.to_s)
        # ActiveRecord::Base keeps track of direct descendants
        const = self.const(name)
        const.superclass.direct_descendants.delete(const)

        remove_const(name) 
        @constants.delete(name.to_s)
      end
    end

    def reset!
      return unless @constants
      @constants.dup.each {|name| remove_klass(name) }
    end

    def reload!
      reset!
      ElementDescriptor.all.each do |descriptor|
        Compiler.new(descriptor).compile
      end
    end

  end
end
