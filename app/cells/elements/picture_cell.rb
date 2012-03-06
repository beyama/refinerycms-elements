module Elements
  class PictureCell < Cell::Base
    include ActionView::Helpers::TagHelper 

    def display(options)
      @element = options[:element]
      render
    end

  end
end
