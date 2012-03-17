module Elements
  class EssenceResource < Essence
    belongs_to :value, :class_name => '::Refinery::Resource'

    def serializable_hash(options=nil)
      if value.present? 
        hash = value.serializable_hash
        hash['href'] = value.url
        hash['html'] = "#{value.title} (#{value.file_name})"
        hash
      else
        nil
      end
    end

  end
end
