require 'spec_helper'
require File.expand_path('../../../spec_helper', __FILE__)

describe Elements::ElementBuilder::PropertyBuilder do
  before(:each) do
    @property = Elements::ElementProperty.new
    @builder  = Elements::ElementBuilder::PropertyBuilder.new(@property)
  end

  %w(title description pattern default enum widget required minimum maximum).each do |method|
    it "should respond to :#{method}" do
      @builder.should be_respond_to(method)
    end
  end

  %w(title description pattern default widget).each do |property|

    it "should delegate #{property} to ElementProperty##{property}=" do
      @builder.send(property, "foo")
      @property[property].should == "foo"
    end

  end

  it "should delegate enum to ElementProperty#enum=" do
    @builder.enum ['foo']
    @property.enum.should == ['foo']
  end

  it "should delegate required to ElementProperty#required=" do
    @builder.required true
    @property.required.should == true
  end

  it "should delegate minimum to ElementProperty#minimum=" do
    @builder.minimum 1
    @property.minimum.should == 1
  end

  it "should delegate maximum to ElementProperty#maximum=" do
    @builder.maximum 8
    @property.maximum.should == 8
  end

  describe "#items" do

    it "should build ElementPropertyItem´s from array of type names" do
      types = %w(Article Picture Gallery)
      @builder.items types
      @property.items.length.should == 3
      @property.items.map(&:typename).should == types
      @property.items.map(&:position).should == [0, 1, 2]
    end

    it "should stringify and camelcase typenames" do
      @builder.items [:article_element, :picture]
      @property.items.map(&:typename).should == %w(ArticleElement Picture)
    end

  end

end # PropertyBuilder

describe Elements::ElementBuilder do

  before(:each) do
    @descriptor = Elements::ElementDescriptor.create :name => 'TestElement'
    @builder = Elements::ElementBuilder.new(@descriptor)
  end

  %w(title description).each do |attribute|
    it "should respond to #{attribute}" do
      @builder.should be_respond_to(attribute)
    end

    it "should delegate #{attribute} to ElementDescriptor##{attribute}=" do
      @builder.send(attribute, 'foo')
      @descriptor[attribute].should == 'foo'
    end
  end

  describe "#property" do

    it "should stringify name" do
      @builder.property(:text_property, 'Text').name.should == 'text_property'
    end

    it "should stringify and camelcase typename" do
      @builder.property(:text_property, :text).typename.should == 'Text'
    end

    it "should yield a PropertyBuilder if a block given" do
      @builder.property(:text_property, :text) do |builder|
        builder.should be_instance_of(Elements::ElementBuilder::PropertyBuilder)
        builder.minimum 1
      end.minimum.should == 1
    end

    it "should append new properties to the bottom of the list" do
      @builder.property(:text_property, :text).position.should == 0
      @builder.property(:text_property2, :text).position.should == 1
    end

    it "should update type of an existing property" do
      @builder.property(:test, :text) 
      @builder.property(:test, :integer).typename == 'Integer'
    end

    it "should update attributes of an existing property" do
      @builder.property(:test, :text) 
      @builder.property(:test, :text, :widget => 'Foo').widget == 'Foo'
    end

    describe "insert before and after" do

      before(:each) do
        3.times {|i| @builder.property("property#{i}", :text) }
      end

      it "should insert before a named property" do
        property = @builder.property(:new_property, :text, :after => :property1)
        property.position.should == 2
        
        @descriptor.properties(true).map(&:name).should == %w(property0 property1 new_property property2)
        @descriptor.properties.map(&:position).should == [0, 1, 2, 3]
      end

      it "should insert after a named property" do
        property = @builder.property(:new_property, :text, :before => :property1)
        property.position.should == 1
        
        @descriptor.properties(true).map(&:name).should == %w(property0 new_property property1 property2)
        @descriptor.properties.map(&:position).should == [0, 1, 2, 3]
      end

    end

  end # #property

  describe "#parent" do

    before(:each) do
      @parent = Elements::ElementDescriptor.create :name => "ParentElement"
    end

    it "should resolve parent by name" do
      @builder.parent "ParentElement"
      @descriptor.parent.should == @parent
    end

    it "should stringify and camelcase parents name" do
      @builder.parent :parent_element
      @descriptor.parent.should == @parent
    end

    it "should raise ParentNotFound unless parent exists" do
      lambda do
        @builder.parent "NotExistingParent"
      end.should raise_error(Elements::ElementBuilder::ParentNotFound, "Parent `NotExistingParent` not found.")
    end

  end 


  Elements::Types::ESSENCES.each_pair do |typename, _|

    describe "##{typename.underscore}" do
      it "should call property with typename `#{typename}`" do
        @builder.should_receive(:property).once.with(:test_property, typename, {})
        @builder.send(typename.underscore, :test_property)
      end
    end

  end

  describe "#array" do
    it "should create an array property" do
      @builder.array(:test_property).typename.should == 'Array'
    end

    it "should create an array property with itmes" do
      property = @builder.array(:test_property, :items => [:type_1, :type_2])
      property.typename.should == 'Array'
      property.items.map(&:typename).should == %w(Type1 Type2)
    end
  end

  describe "#create" do
    it "should build and save an element descriptor" do
      element = Elements::ElementBuilder.create 'TestElement2'
      element.name.should == 'TestElement2'
      element.should be_persisted
    end

    it "should stringify and camelcase the name" do
      Elements::ElementBuilder.create(:test_element2).name.should == 'TestElement2'
    end

    it "should yield a given block" do
      Elements::ElementBuilder.create(:test_element2) do |e|
        e.text :test_property
      end.properties.size.should == 1
    end
  end

  describe "#update" do

    it "should raise exception unless descriptor exists" do
      lambda do
        Elements::ElementBuilder.update(:foo) {}
      end.should raise_error(Elements::ElementBuilder::DescriptorNotFound, "Descriptor `Foo` not found.")
    end

    it "should update descriptor" do
      Elements::ElementBuilder.update(:test_element, :title => 'foo')
      Elements::ElementDescriptor.find_by_name('TestElement').title.should == 'foo'
    end

    it "should update descriptor with block" do
      Elements::ElementBuilder.update(:test_element) do |b|
        b.title 'foo'
      end
      Elements::ElementDescriptor.find_by_name('TestElement').title.should == 'foo'
    end
  end

  describe "#create_or_update" do
    it "should create descriptor unless exists" do
      Elements::ElementDescriptor.find_by_name('TestElement2').should be_nil
      Elements::ElementBuilder.create_or_update(:test_element2)
      Elements::ElementDescriptor.find_by_name('TestElement2').should_not be_nil
    end

    it "should update descriptor if exists" do
      Elements::ElementBuilder.create_or_update(:test_element, :title => 'foo')
      Elements::ElementDescriptor.find_by_name('TestElement').title.should == 'foo'
    end

    it "should yield a given block" do
      Elements::ElementBuilder.create_or_update(:test_element) do |e|
        e.text :test_property
      end.properties.size.should == 1
    end
  end

  describe "#rename_property" do
    before(:each) do
      @property = @builder.text :old_title
    end

    it "should rename an existing property" do
      @builder.rename_property :old_title, :new_title
      @property.name.should == 'new_title'
    end

    it "should raise an exception unless property exists" do
      lambda do
        @builder.rename_property :title, :new_title
      end.should raise_error(Elements::ElementBuilder::PropertyNotFound, "Property `title` not found.")
    end
         
  end

  describe "#remove_property" do
    before(:each) do
      Elements::ElementBuilder.create :article do |b|
        b.text :title, :maximum => 250
        b.text :body
      end

      @builder.text :text_property
      @builder.element :article, :article

      Elements::Types.reload!
      @element = Elements::Types::TestElement.create :text_property => 'foo', :article_attributes => { :title => 'bar' }
    end

    it "should destroy property" do
      @builder.remove_property :article
      @builder.remove_property :text_property
      @descriptor.properties(true).should be_empty
    end

    it "should raise an exception unless property exists" do
      lambda do
        @builder.remove_property :title
      end.should raise_error(Elements::ElementBuilder::PropertyNotFound, "Property `title` not found.")
    end

    it "should destroy property essences" do
      @builder.remove_property :text_property
      @element.text_associations(true).should be_empty
    end

    it "should destroy property elements" do
      @builder.remove_property :article
      @element.element_associations(true).should be_empty
    end

  end

end
