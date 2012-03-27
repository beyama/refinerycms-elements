module Elements
  module Testing
    module CompilerMacros

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

      def create_and_compile_some_document_desciptors
        before do
          Elements::ElementDescriptor.delete_all

          doc = Elements::ElementDescriptor.new :name => 'DocumentElement'
          doc.properties.build(:name => 'title', :title => 'Title', :typename => 'Text', :minimum => 1, :maximum => 250, :required => true, :position => 0)
          doc.save!

          descriptor 'ArticleDocument' do |desc|
            desc.parent doc
          end
          compile
        end
      end

    end
  end
end
