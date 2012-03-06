module Elements
  class RichTextCell < Cell::Base
    include ActionView::Helpers::TagHelper 

    def display(options)
      @element = options[:element]
      if @element.text.present? 
        content_tag 'div', @element.text.html_safe, :class => 'element richtext'
      end
    end

  end
end
