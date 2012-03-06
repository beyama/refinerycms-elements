module Elements
  module SpecHelper

    def descriptor(name, attributes={}, &block)
      @descriptor = Elements::ElementBuilder.create(name, attributes, &block)
    end

    def property(name, type, attributes={}, &block)
      @property = Elements::ElementBuilder.new(@descriptor).property(name, type, attributes, &block)
      @property.save!
      @property
    end

    def compile(descriptor=@descriptor)
      @klass = Elements::Compiler.new(descriptor).compile
    end

  end
end
