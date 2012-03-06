module Elements
  class EssenceImage < Essence
    belongs_to :value, :class_name => '::Image'

    def serializable_hash(options=nil)
      value.present? ? Elements::Commons.image_to_hash(value) : nil
    end

  end
end
