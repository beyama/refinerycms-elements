module Elements

  class << self
    attr_accessor :root
    def root
      @root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end

  class Engine < Rails::Engine
    include Refinery::Engine

    isolate_namespace Elements

    engine_name :refinery_elements

#      initializer "elements widgets" do
#        ::Elements::Widget.register 'EssenceTextView', ['Text']
#
#        ::Elements::Widget.register 'EssenceNumberView', ['Integer', 'Float']
#
#        ::Elements::Widget.register 'EssenceBooleanView', ['Boolean']
#
#        ::Elements::Widget.register 'EssenceRichTextView', ['Text']
#
#        ::Elements::Widget.register 'EssenceImageView', ['Image']
#
#        ::Elements::Widget.register 'EssenceResourceView', ['Resource']
#
#        ::Elements::Widget.register 'EssenceColorView', ['Text']
#
#        ::Elements::Widget.register 'ListView', ['Array']
#
#        ::Elements::Widget.register 'PictureView', ['Picture']
#
#        ::Elements::Widget.register 'PictureListView', ['Array']
#
#        ::Elements::Widget.register 'GalleryView', ['Gallery']
#
#        ::Elements::Widget.register 'RichTextView', ['RichText']
#      end

    initializer "elements compiler" do |app|
      app.middleware.insert_after Rack::Cache, ::Elements::CompilerMiddleware
    end

    initializer "elements widget view paths", :after => "apotomo.setup_view_paths" do
      Cell::Base.append_view_path root.join('app/cells')
      Apotomo::Widget.append_view_path root.join('app/widgets')
    end

    ActiveSupport.on_load(:action_view) do
      include ::Elements::ActionViewExtension
    end

    after_inclusion do
      Refinery::Page.class_eval do
        include ::Elements::HasManyElements
        attr_accessible :elements_attributes
      end

      # Load element model to trigger reload of element subclasses.
      ::Elements::Element

      Refinery::Admin::PagesController.send(:include, ::Elements::PagesControllerExtension)
    end

    initializer "register refinery_elements plugin" do
      Refinery::Plugin.register do |plugin|
        plugin.pathname = root
        plugin.name = 'refinery_elements'
        plugin.version = %q{0.1.0}
        plugin.menu_match = /^\/?refinery\/elements\/?documents?/
        plugin.class_name = 'Elements'
        plugin.activity = {
          :class_name => :'elements/document'
        }
        plugin.url = { :controller => 'refinery/admin/elements/documents', :action => :index }
      end
    end

    config.after_initialize do
      Refinery.register_extension(Elements)
       
      ::Refinery::Pages::Tab.register do |tab|
        tab.name = "elements"
        tab.partial = "refinery/admin/pages/tabs/elements"
      end 
    end
  end
end
