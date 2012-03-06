module Elements
  module HasManyElements
    extend ActiveSupport::Concern 

    included do
      has_many :elements, 
        :as => :attachable, 
        :class_name => '::Elements::Element', 
        :autosave => true,
        :dependent => :destroy

      scope :elements_with_locale, proc {|locales|
        locales = [locales] if locales.is_a?(String)
        joins(:elements).where("elements.locale in (?)", locales)
      }

      scope :with_essence, proc {|essences| 
        joins = []
        essences = [essences] if essences.is_a?(String)
        essences.each do |essence|
          joins << "INNER JOIN #{essence} ON #{essence}.element_id = elements.id"
        end
        self.joins(joins.join(' '))
      }

      scope :search_in_elements, proc {|properties, query|
        sql = []
        essences = []
        properties = [properties] unless properties.is_a?(Array)
        properties.each do |property|
          association_name = Elements::Element.association_name_for_property(property)
          association = Elements::Element.reflect_on_association(association_name)
          table = association.quoted_table_name
          essences << table
          sql << "#{table}.property_id = #{property.id} AND #{table}.value like :query"
        end
        self.with_essence(essences.uniq).where(sql.join(' OR '), :query => '%' + query + '%')
      }

      def elements_attributes=(attributes)
        array = ::Elements::ElementArray.new(self, nil, :association_name => :elements, :sortable => false)
        array.assign_attributes(attributes)
      end
    end

    module InstanceMethods

      def element_translation
        if @element_translation.nil? || @element_translation.locale != Globalize.locale
          @element_translation = self.elements.with_locale(Globalize.locale).first
        end

        @element_translation
      end

      def element_title
        element_translation ? element_translation.title : nil
      end

    end

  end
end
