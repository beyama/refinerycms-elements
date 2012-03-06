require 'spec_helper'

describe Elements::ElementProperty do

  before(:each) do
    Elements::ElementBuilder.create :article
    Elements::Types.reload!
  end

  def property(attributes={})
    Elements::ElementProperty.new(attributes)
  end

  def valid_attributes
    { :name => 'title', :typename => 'Text' }
  end

  context 'validations' do

    it 'should validate with legal names' do
      %w(article my_article article_34).each do |legal_name|
        property(valid_attributes.update(:name => legal_name)).should be_valid
      end
    end

    it 'should not validate with illegal names' do
      %w(Article MyArticle myArticle 34article).each do |illegal_name|
        property(valid_attributes.update(:name => illegal_name)).should_not be_valid
      end
    end

    it 'should not allow names of ActiveRecord instance methods' do
      property(valid_attributes.update(:name => 'read_attribute')).should_not be_valid
      property(valid_attributes.update(:name => 'to_param')).should_not be_valid
    end

    it 'should not allow names reserved endings' do
      %w(_id _attributes _type = ! ?).each do |ending|
        property(valid_attributes.update(:name => 'article' + ending)).should_not be_valid
      end
    end

  end

  describe "#essence?" do

    it "returns false if type is a kind of element" do
      property(:typename => 'Article').should_not be_essence
    end

    it "returns true if type is an essence" do
      property(:typename => 'Text').should be_essence
    end

  end

  describe "#element?" do

    it "returns false if type is an essence" do
      property(:typename => 'Text').should_not be_element
    end

    it "returns true if type is a kind of element" do
      property(:typename => 'Article').should be_element
    end

  end

  describe "#array?" do

    it "returns false if type is an essence" do
      property(:typename => 'Text').should_not be_array
    end

    it "returns false if type is a kind of element" do
      property(:typename => 'Article').should_not be_array
    end

    it "returns true if type is array" do
      property(:typename => 'Array').should be_array
    end

  end

  describe "#klass" do

    it "returns the essence klass if property is an essence" do
      Elements::Types::ESSENCES.each_pair do |type, klass|
        property(:typename => type).klass.should == klass.constantize
      end
    end

    it "returns the element klass if property is an element" do
      property(:typename => 'Article').klass.should == Elements::Types::Article
    end

  end

end
