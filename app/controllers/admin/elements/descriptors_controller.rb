module Admin
  module Elements
    class DescriptorsController < Admin::BaseController
      respond_to :json, :only => :index
      respond_to :js, :only => :widgets

      def index
        @descriptors = ::Elements::ElementDescriptor.all
        respond_with(@descriptors)
      end

      def widgets
      end

      protected

      def store_current_location!
        super unless action_name == 'widgets'
      end 

    end
  end
end
