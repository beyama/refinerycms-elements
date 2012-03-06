module NavigationHelpers
  module Refinery
    module Elements
      def path_to(page_name)
        case page_name
        when /the list of documents/
          admin_elements_documents_path
        when /the new document form/
          new_admin_elements_document_path
        when /the document titled "?([^\"]*)"?/
          descriptor = ::Elements::Types::DocumentElement.descriptor
          property = descriptor.properties.to_a.find {|p| p.name == 'title' }

          doc = ::Elements::Document.joins(:elements).search_in_elements(property, $1).first

          edit_admin_elements_document_path(doc)
        else
          nil
        end
      end
    end
  end
end
