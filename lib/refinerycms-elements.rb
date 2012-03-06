require 'refinerycms-base'
require 'acts_as_list'
require 'apotomo'

require 'elements'

Apotomo.js_framework = :jquery

module Refinery
  module Elements

    class << self
      attr_accessor :root
      def root
        @root ||= Pathname.new(File.expand_path('../../', __FILE__))
      end
    end

    class Engine < Rails::Engine

      initializer "elements widgets" do
        ::Elements::Widget.register 'EssenceTextView', ['Text']

        ::Elements::Widget.register 'EssenceNumberView', ['Integer', 'Float']

        ::Elements::Widget.register 'EssenceBooleanView', ['Boolean']

        ::Elements::Widget.register 'EssenceRichTextView', ['Text']

        ::Elements::Widget.register 'EssenceImageView', ['Image']

        ::Elements::Widget.register 'EssenceResourceView', ['Resource']

        ::Elements::Widget.register 'EssenceColorView', ['Text']

        ::Elements::Widget.register 'ListView', ['Array']

        ::Elements::Widget.register 'PictureView', ['Picture']

        ::Elements::Widget.register 'PictureListView', ['Array']

        ::Elements::Widget.register 'GalleryView', ['Gallery']

        ::Elements::Widget.register 'RichTextView', ['RichText']
      end

      initializer "static assets" do |app|
        app.middleware.insert_after ::ActionDispatch::Static, ::ActionDispatch::Static, "#{root}/public"
      end

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

      refinery.after_inclusion do
        ::Page.class_eval do
          include ::Elements::HasManyElements
          attr_accessible :elements_attributes
        end

        # Load element model to trigger reload of element subclasses.
        ::Elements::Element

        ::Admin::PagesController.send(:include, ::Elements::PagesControllerExtension)
      end

      config.after_initialize do
        Refinery::Plugin.register do |plugin|
          plugin.name = "refinerycms_elements"
          plugin.url = { :controller => 'admin/elements/documents', :action => :index }
          plugin.pathname = root
          plugin.menu_match = /^\/?(admin|refinery)\/elements\/?(documents|descriptors)?/
          plugin.activity = {
            :class => ::Elements::Element
          }
        end

        ::Refinery::Pages::Tab.register do |tab|
          tab.name = "elements"
          tab.partial = "/admin/pages/tabs/elements"
        end 
      end
    end
  end
end
