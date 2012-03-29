module Refinery
  module Admin
    module Elements
      class DocumentsController < ::Refinery::AdminController
        include Apotomo::Rails::ControllerMethods

        has_widgets do |root|
          root << widget('admin/elements/image_cropper', 'image_cropper')
        end

        crudify 'elements/document',
                :conditions => nil,
                :order => "lft ASC",
                :include => [:elements, :children],
                :paging => false,
                :singular_name => 'document',
                :plural_name => 'documents',
                :redirect_to_url => 'refinery.admin_elements_documents_path'

        before_filter :find_descriptors, :only => [:new, :edit, :create, :update]

        def new
          @document = ::Elements::Document.new(:parent_id => params[:parent_id])
        end

        protected

        def find_all_documents
          @documents = ::Elements::Document
        end

        def search_all_documents
          find_all_documents

          if searching?
            descriptor = ::Elements::Types::DocumentElement.descriptor
            property = descriptor.properties.to_a.find {|p| p.name == 'title' }

            @documents = @documents.joins(:elements).search_in_elements(property, params[:search]) 
          end
        end

        def find_descriptors
          @descriptors = ::Elements::ElementDescriptor.includes(:properties => :items).all 
        end

      end
    end
  end
end
