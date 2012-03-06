require 'spec_helper'
require File.expand_path('../../../spec_helper', __FILE__)

describe Elements::ElementArray do

  include Elements::SpecHelper

  before(:each) do
    Elements::Types.reset!
  end

  context 'load elements' do

    it 'should load elements from association proxy' do
      descriptor 'Foo' do |desc|
        desc.element 'bar',  'Element'
        @list = desc.element 'list', 'Array'
      end
      compile

      element = @klass.new

      3.times do |i|
        element.element_associations.build :position => i, :property_id => @list.id
      end

      ary = Elements::ElementArray.new(element, @list)

      ary.count.should == 3

      ary.each_with_index do |e,i|
        e.should == element.element_associations[i]
      end
    end

  end # context

  context 'element builder' do

    before(:each) do
      descriptor 'Foo'
      compile

      descriptor 'Bar'
      compile

      descriptor 'FooBar' do |desc|
        @list = desc.array 'list'
      end
      compile

      @element = @klass.new
      @array = Elements::ElementArray.new(@element, @list)
    end

    it 'should raise ArgumentError if no type given' do
      lambda do
        @array.build
      end.should raise_error(ArgumentError)
    end

    it 'should raise Elements::TypeError if type not exist' do
      lambda do
        @array.build :type => 'Boom'
      end.should raise_error(Elements::TypeError)
    end
    
    it 'should build and add elements' do
      foo = @array.build :type => 'Foo'
      
      foo.should be_kind_of Elements::Types::Foo
      foo.position.should == 0
      foo.property_id.should == @list.id
      foo.attachable.should == @element

      @element.element_associations.size.should == 1
      @array.size.should == 1

      bar = @array.build :type => 'Bar'
      
      bar.should be_kind_of Elements::Types::Bar
      bar.position.should == 1

      @element.element_associations.size.should == 2
      @array.size.should == 2
    end

    it 'should adjust position' do
      foo = @array.build :type => 'Foo', :position => 10
      foo.position.should == 0
      @array.first.should == foo

      bar = @array.build :type => 'Bar', :position => -1
      bar.position.should == 0
      @array.first.should == bar
    end

    it 'should not set position field if sortable is false' do
      array = Elements::ElementArray.new(@element, @list, :sortable => false)
      foo = array.build :type => 'Foo'
      foo.position.should be_nil

      foo = array.build :type => 'Foo', :position => 1
      foo.position.should be_nil
    end

  end # context

  context 'massassignement' do

    before(:each) do
      descriptor 'Foo' do |desc|
        desc.text 'text'
      end
      compile

      descriptor 'FooBar' do |desc|
        @list = desc.array 'list'
      end
      compile

      @element = @klass.new
      @array = Elements::ElementArray.new(@element, @list)
      @attributes = { :type => 'Foo', :text => 'Lorem ipsum...' }
    end

    it 'should raise an ArgumentError unless attributes is a hash or an array' do
      lambda do
        @array.assign_attributes("foo")
      end.should raise_error(ArgumentError)
    end

    it 'should build elements from hash' do
      @array.assign_attributes({ '1' => @attributes })

      @array.length.should == 1
      @array.first.should be_kind_of Elements::Types::Foo
      @array.first.text.should == @attributes[:text]
    end

    it 'should build elements from array' do
      @array.assign_attributes([@attributes])

      @array.length.should == 1
      @array.first.should be_kind_of Elements::Types::Foo
      @array.first.text.should == @attributes[:text]
    end

    context 'on update' do

      before(:each) do
        3.times do |i|
          e = @array.build(:type => 'Foo', :text => "Element #{i}")
        end

        @element.save!
      end

      it 'should update elements from array' do
        array = @array.map { |e| { :id => e.id, :text => e.text + ' updated' } }
        @array.assign_attributes(array)

        @array.length.should == 3
        @array[1].text.should == 'Element 1 updated'

        @element.element_associations == @array
      end

      it 'should update elements from hash' do
        hash = {}
        @array.each_with_index { |e, i| hash[i] = { :id => e.id, :text => e.text + ' updated' } }
        @array.assign_attributes(hash)

        @array.length.should == 3
        @array[1].text.should == 'Element 1 updated'

        @element.element_associations == @array
      end

      it 'should update single element from hash' do
        e = @array.last
        @array.assign_attributes({:id => e.id, :text => e.text + ' updated' })

        @array.length.should == 3
        @array[2].text.should == 'Element 2 updated'

        @element.element_associations == @array
      end

      it 'should delete elements from array' do
        @array.last.position.should == 2

        e = @array[1]
        @array.assign_attributes({:id => e.id, :_destroy => true})

        @array.length.should == 2
        @array.should_not be_include e

        @array.last.position.should == 1
        @element.element_associations == @array
      end

    end # context

  end # context

end
