module Elements
  module ActionViewExtension

    # Get cell name for element
    def cell_name_for_element(element)
      name = "elements/#{element.class.name.demodulize.underscore}"
      cell = Cell::Base.class_from_cell_name(name) rescue nil
      return name if cell

      klass = element.class
      while (klass = klass.superclass)
        name = "elements/#{klass.name.demodulize.underscore}"
        cell = Cell::Base.class_from_cell_name(name) rescue nil
        return name if cell
      end
    end

    # Render cell for element
    def render_element(element, state, *args, &block)
      name = cell_name_for_element(element)
      if name
        if args.last.is_a?(Hash)
          args.last[:element] ||= element
        else
          args << { :element => element }
        end
        render_cell(name, state, *args, &block)
      else
        content_tag 'p', "No cell found for element `#{element.inspect}`."
      end
    end

  end
end
