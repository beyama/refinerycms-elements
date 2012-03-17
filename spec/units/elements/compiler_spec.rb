require 'spec_helper'
require File.expand_path('../../../spec_helper', __FILE__)

describe Elements::Compiler do

  include Elements::SpecHelper

  before(:each) do
    Elements::Types.reset!
  end

  context 'inheritance' do

    it 'should inherit from Element if no parent specified' do
      descriptor 'Foo'
      compile

      @klass.superclass.should == Elements::Element
    end

    it 'should inherit from parent if specified' do
      descriptor 'Foo'
      compile

      descriptor 'Bar', :parent => @descriptor
      compile

      @klass.superclass.should == Elements::Types::Foo
    end

    it 'should autocompile parent' do
      descriptor 'Foo'

      Elements::Types.const('Foo').should be_nil

      descriptor 'Bar', :parent => @descriptor
      compile
      
      Elements::Types.const('Foo').should_not be_nil

      @klass.superclass.should == Elements::Types::Foo
    end

  end

  context 'compilation of essence properties' do

    before(:each) do
      descriptor 'Struct' do |desc|
        Elements::Types::ESSENCES.each_pair do |type, klass|
          desc.property(type.underscore, type)
        end
      end
      compile
      
      @any = @descriptor.properties.to_a.find{|p| p.name == 'any' }
    end

    it 'should define accessors' do
      instance = @klass.new
      Elements::Types::ESSENCES.each_pair do |type, klass|
        instance.should be_respond_to type.underscore
        instance.should be_respond_to "#{type.underscore}="

        if %w(Image Resource Any).include?(type)
          instance.should be_respond_to "#{type.underscore}_id"
          instance.should be_respond_to "#{type.underscore}_id="
        end

      end
    end

    it 'should delegate reader' do
      instance = @klass.new
      user     = ::Refinery::User.new
      user.id  = 23
      instance.any_associations.build(:property_id => @any.id, :value => user)

      instance.any.should == user
      instance.any_id.should == 23
      instance.any_type.should == 'Refinery::User'
    end

    it 'should delegate writer' do
      instance = @klass.new
      user     = ::Refinery::User.new
      user.id  = 23

      instance.any = user

      instance.any_associations.first.value.should == user

      instance.any.should == user
      instance.any_id.should == 23
      instance.any_type.should == 'Refinery::User'

      instance.any_id *= 2
      instance.any_id.should == 46

      instance.any_type = 'foo'
      instance.any_type.should == 'foo'
    end

  end # context

  context 'compilation of element properties' do

    before(:each) do
      @article = descriptor 'Article' do |desc|
        desc.text :headline
        desc.text :intro
        desc.text :body
        desc.image :image
      end

      @page = descriptor 'StandardPage' do |desc|
        desc.element :article, :article
      end

      compile(@page)
      compile(@article)
    end

    it 'should generate setter' do
      @page = Elements::Types::StandardPage.new
      @page.article.should be_nil
      @page.element_associations.should be_empty

      article = Elements::Types::Article.new
      @page.article = article

      @page.element_associations.length.should == 1
      @page.element_associations.first.should == article
    end

    it 'should generate attributes delegator' do
      @page = Elements::Types::StandardPage.new

      attributes = { 
        :headline => 'New Refinery Elements version released', 
        :body => 'Lorem Ipsum ...' 
      }

      @page.article_attributes = attributes
      @page.article.should be_kind_of Elements::Types::Article

      @page.article.headline.should == attributes[:headline]
      @page.article.body.should == attributes[:body]
    end

  end # context

  context 'compilation of arrays' do

    before(:each) do
      descriptor 'Foo' do |desc|
        desc.array :list, :items => ['Element']
      end
      compile
    end

    it 'should generate getter' do
      Elements::Types::Foo.new.list.should be_kind_of Array
    end

    it 'should generate attributes setter' do
      Elements::Types::Foo.new.should be_respond_to :list_attributes=
    end

  end # context

  context 'compilation of numeric properties' do

    before(:each) do
      descriptor 'Foo'
    end
    
    it 'should setup minimum validation' do
      property 'integer', 'Integer', :minimum => 5
      property 'float',   'Float',   :minimum => 1.2
      compile

      @klass.new(:integer => 1).should_not be_valid
      @klass.new(:integer => 6).should be_valid

      @klass.new(:float => 0.5).should_not be_valid
      @klass.new(:float => 1.3).should be_valid
    end

    it 'should setup maximum validation' do
      property 'integer', 'Integer', :maximum => 5
      property 'float',   'Float',   :maximum => 1.2
      compile

      @klass.new(:integer => 6).should_not be_valid
      @klass.new(:integer => 5).should be_valid

      @klass.new(:float => 1.5).should_not be_valid
      @klass.new(:float => 1.1).should be_valid
    end

    it 'should setup `inclusion_of` validation on enums' do
      property 'integer', 'Integer', :enum => [1, 2, 4]
      property 'float',   'Float',   :enum => [1.0, 2.0, 4.0]
      compile

      @klass.new(:integer => 3).should_not be_valid
      @klass.new(:integer => 4).should be_valid

      @klass.new(:float => 3.0).should_not be_valid
      @klass.new(:float => 1.0).should be_valid
    end


  end

  context 'compilation of text properties' do

    before(:each) do
      descriptor 'Foo'
    end
    
    it 'should setup minimum length validation' do
      property 'string', 'Text', :minimum => 5
      compile

      @klass.new(:string => 'abcd').should_not be_valid
      @klass.new(:string => 'abcde').should be_valid
    end

    it 'should setup maximum length validation' do
      property 'string', 'Text', :maximum => 3
      compile

      @klass.new(:string => 'abcd').should_not be_valid
      @klass.new(:string => 'abc').should be_valid
    end

    it 'should setup format validation' do
      property 'string', 'Text', :pattern => '\w+-\d{3}'
      compile

      @klass.new(:string => 'abcd').should_not be_valid
      @klass.new(:string => 'abcd-123').should be_valid
    end

    it 'should setup `inclusion_of` validation on enums' do
      property 'string', 'Text', :enum => %w(green red blue)
      compile

      @klass.new(:string => 'black').should_not be_valid
      @klass.new(:string => 'red').should be_valid
    end

  end

end
