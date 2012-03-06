module Elements
  class GalleryCell < Cell::Base
    include ActionView::Helpers::TagHelper 

    def display(options)
      @element = options[:element]
      @pictures = @element.pictures
      return "" if @pictures.empty?
      render
    end

  end
end
