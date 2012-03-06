class CreateElementsStructure < ActiveRecord::Migration
  BASE_TYPES = %w(text integer float boolean date datetime)

  def self.up
    BASE_TYPES.each do |type|
      create_table "essence_#{type.pluralize}" do |t|
        t.belongs_to :element, :null => false
        t.belongs_to :property, :null => false
        t.send type, :value, :null => false
      end
    end

    create_table :essence_images do |t|
      t.belongs_to :element, :null => false
      t.belongs_to :property, :null => false
      t.belongs_to :value
    end

    create_table :essence_resources do |t|
      t.belongs_to :element, :null => false
      t.belongs_to :property, :null => false
      t.belongs_to :value
    end

    create_table :essence_any do |t|
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

    create_table :element_descriptors do |t|
      t.string     :name, :null => false, :limit => 100
      t.string     :title
      t.text       :description
      t.boolean    :system, :default => false
      t.belongs_to :parent

      t.timestamps
    end
    add_index :element_descriptors, :name, :unique => true

    create_table :element_properties do |t|
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
    add_index :element_properties, [:name, :descriptor_id], :unique => true

    create_table :element_property_items do |t|
      t.belongs_to :property
      t.string     :typename
      t.integer    :position
    end

    create_table :element_documents do |t|
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt

      t.timestamps
    end

    load(Rails.root.join('db', 'seeds', 'elements.rb'))
  end

  def self.down
    if defined?(UserPlugin)
      UserPlugin.destroy_all({:name => "elements"})
    end

    BASE_TYPES.each {|type| drop_table "essence_#{type.pluralize}" }
    drop_table :essence_images
    drop_table :essence_resources
    drop_table :essence_any
    drop_table :elements
    drop_table :element_descriptors
    drop_table :element_properties
    drop_table :element_property_items
    drop_table :element_documents
  end

end
