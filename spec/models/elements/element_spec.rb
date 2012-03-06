require 'spec_helper'

describe Elements::Element do

  context 'property accessors' do

    it 'should read essences' do
      element = Elements::Element.new
      
      id = 1
      Elements::Types::ESSENCES.each_pair do |type, klass|
        name     = type.underscore
        property = Elements::ElementProperty.new(:name => name, :typename => type)
        property.id = id

        essence  = property.klass.new(:property_id => id)
        element.association_for_property(property) << essence

        element.read_property(property).should == essence

        id += 1
      end
    end

    it 'should read element' do
      element     = Elements::Element.new
      property    = Elements::ElementProperty.new(:name => 'child_element', :typename => 'Element')
      property.id = 1

      child_element = element.element_associations.build :property_id => property.id
      element.read_property(property).should == child_element
    end

    it 'should write essences' do
      element = Elements::Element.new
      
      id = 1
      Elements::Types::ESSENCES.each_pair do |type, klass|
        name     = type.underscore
        property = Elements::ElementProperty.new(:name => name, :typename => type)
        property.id = id

        essence  = property.klass.new
        element.write_property(property, essence)

        element.read_property(property).should == essence

        essence.property_id.should == property.id

        id += 1
      end
    end

    it 'should write element' do
      element     = Elements::Element.new
      property    = Elements::ElementProperty.new(:name => 'child_element', :typename => 'Element')
      property.id = 1

      element.element_associations.should be_empty

      child_element = Elements::Element.new

      element.write_property(property, child_element)

      element.element_associations.size.should == 1
      element.element_associations.first.should == child_element

      child_element.property_id.should == property.id
      child_element.attachable.should == element
    end

    it 'should overwrite essences' do
      element = Elements::Element.new

      element.text_associations.should be_empty
      
      property = Elements::ElementProperty.new(:name => 'title', :typename => 'Text')
      property.id = 1

      title = Elements::EssenceText.new :value => 'Awesome article'
      element.write_property(property, title)

      element.text_associations.length.should == 1
      element.text_associations.first.value.should == 'Awesome article'

      title = Elements::EssenceText.new :value => 'Bad news'
      element.write_property(property, title)

      element.text_associations.length.should == 1
      element.text_associations.first.value.should == 'Bad news'
    end

    it 'should overwrite element' do
      element = Elements::Element.new

      element.element_associations.should be_empty
      
      property = Elements::ElementProperty.new(:name => 'child_element', :typename => 'Element')
      property.id = 1

      child_element = Elements::Element.new
      element.write_property(property, child_element)

      element.element_associations.length.should == 1
      element.element_associations.first.should == child_element

      child_element = Elements::Element.new
      element.write_property(property, child_element)

      element.element_associations.length.should == 1
      element.element_associations.first.should == child_element
    end

    it 'should read array of elements' do
      element = Elements::Element.new
    
      property = Elements::ElementProperty.new(:name => 'list', :typename => 'Array')
      property.id = 1

      elements = []

      10.times do |i|
        elements << element.element_associations.build(:position => i, :property_id => property.id)
      end

      proxy = element.read_property(property)
      
      proxy.length.should == 10
      proxy.should == elements
    end
        
  end # context

end
