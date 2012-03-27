class CreateElementsStructure < ActiveRecord::Migration
  BASE_TYPES = %w(text integer float boolean date datetime)

  def self.up
    BASE_TYPES.each do |type|
      create_table "elements_essence_#{type.pluralize}" do |t|
        t.belongs_to :element, :null => false
        t.belongs_to :property, :null => false
        t.send type, :value, :null => false
      end
    end

    create_table :elements_essence_images do |t|
      t.belongs_to :element, :null => false
      t.belongs_to :property, :null => false
      t.belongs_to :value
    end

    create_table :elements_essence_resources do |t|
      t.belongs_to :element, :null => false
      t.belongs_to :property, :null => false
      t.belongs_to :value
    end

    create_table :elements_essence_any do |t|
      t.belongs_to :element, :null => false
      t.belongs_to :property, :null => false
      t.belongs_to :value, :polymorphic => true
    end

    create_table :elements do |t|
      t.string     :type
      t.string     :locale, :limit => 6
      t.string     :css_class, :limit => 50
      t.integer    :position
      t.belongs_to :property
      t.belongs_to :attachable, :polymorphic => true

      t.timestamps
    end
    add_index :elements, :type
    add_index :elements, [:attachable_id, :attachable_type, :locale], :unique => true

    create_table :elements_element_descriptors do |t|
      t.string     :name, :null => false, :limit => 100
      t.string     :title
      t.text       :description
      t.boolean    :system, :default => false
      t.belongs_to :parent

      t.timestamps
    end
    add_index :elements_element_descriptors, :name, :unique => true

    create_table :elements_element_properties do |t|
      t.string     :name, :limit => 100
      t.string     :title
      t.text       :description
      t.string     :typename
      t.text       :enum
      t.boolean    :required
      t.string     :pattern
      t.float      :minimum
      t.float      :maximum
      t.string     :default
      t.string     :widget
      t.integer    :position
      t.belongs_to :descriptor

      t.timestamps
    end
    add_index :elements_element_properties, [:name, :descriptor_id], :unique => true

    create_table :elements_element_property_items do |t|
      t.belongs_to :property
      t.string     :typename
      t.integer    :position
    end

    create_table :elements_documents do |t|
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt

      t.timestamps
    end

  end

  def self.down
    if defined?(Refinery::UserPlugin)
      Refinery::UserPlugin.destroy_all({:name => "elements"})
    end

    BASE_TYPES.each {|type| drop_table "elements_essence_#{type.pluralize}" }
    drop_table :elements_essence_images
    drop_table :elements_essence_resources
    drop_table :elements_essence_any
    drop_table :elements
    drop_table :elements_element_descriptors
    drop_table :elements_element_properties
    drop_table :elements_element_property_items
    drop_table :elements_documents
  end

end
