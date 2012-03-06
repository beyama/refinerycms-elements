module Elements
  class ElementArrayCell < Cell::Base

    def display(element, association)
      @element = element
      @array = @element.send(association)
      render
    end

  end
end
