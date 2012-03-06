module Elements
  class EssenceAny < Essence
    set_table_name 'essence_any'

    belongs_to :value, :polymorphic => true

    def serializable_hash(options=nil)
      hash = super
      if value.present?
        if value.respond_to?(:serializable_hash_for_elements)
          hash['value_data'] = value.serializable_hash_for_elements
        else
          hash['value_data'] = value.serializable_hash
        end
      end
      hash
    end

  end
end
