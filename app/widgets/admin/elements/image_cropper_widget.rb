module Admin
  module Elements

    class ImageCropperWidget < Apotomo::Widget
      responds_to_event :show, :with => :dialog
      responds_to_event :crop, :with => :crop

      def dialog(ev)
        @image = ::Refinery::Image.find(ev[:id])

        image = @image.image
        @thumb = image.thumb('800x600>')

        data = ::Elements::Commons.image_to_hash(@image)
        data['view'] = render(:view => :display)
        data['cropper_width'] = @thumb.width
        data['cropper_height'] = @thumb.height
        data.to_json
      end

      def crop(ev)
        @image = ::Refinery::Image.find(ev[:id])
        if ev[:save_as_copy]
          @image = ::Refinery::Image.new :image => @image.image.process(:crop, :x => ev[:x], :y => ev[:y], :width => ev[:w], :height => ev[:h]) 
        else
          @image.image.process! :crop, :x => ev[:x], :y => ev[:y], :width => ev[:w], :height => ev[:h] 
        end
        @image.save!
        ::Elements::Commons.image_to_json(@image)
      end

    end

  end
end
