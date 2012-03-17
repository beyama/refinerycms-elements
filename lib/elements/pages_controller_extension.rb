module Elements
  module PagesControllerExtension
    extend ActiveSupport::Concern 

    included do
      before_filter :find_descriptors, :only => [:new, :edit, :create, :update]
      before_filter :find_element_for_current_locale,
        :only => [:update, :destroy, :edit, :show] 
    end

    protected

    def find_element_for_current_locale
      @element = @page.elements.with_locale(Globalize.locale).first
    end

    def find_descriptors
      @descriptors = ::Elements::ElementDescriptor.includes(:properties => :items).all 
    end

  end
end
