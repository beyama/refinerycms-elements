module Elements
  module Commons
    extend self

    def image_to_hash(image)
      hash = image.serializable_hash
      ::Refinery::Images.user_image_sizes.each_pair do |name, size|
        hash["thumbnail_#{name}"] = image.thumbnail(size).url
      end
      hash['thumbnail'] = image.thumbnail('106x106#c').url
      hash['original'] = image.url
      hash
    end

    def image_to_json(image)
      image_to_hash(image).to_json
    end

  end
end
