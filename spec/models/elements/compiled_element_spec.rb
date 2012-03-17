require 'spec_helper'
require File.expand_path('../../../spec_helper', __FILE__)

describe Elements::Element do

  include Elements::SpecHelper

  before do
    @image = ::Refinery::Image.create!(:image => File.new(File.expand_path('../../../images/image.png', __FILE__)))
    @resource = ::Refinery::Resource.create!(:file => File.new(File.expand_path('../../../images/image.png', __FILE__)))
  end

  before(:each) do
    Elements::Types.reset!

    @footer_text = '(c) 2011 beyama'

    # Picture
    descriptor 'Picture' do |desc|
      desc.image 'image'
      desc.text 'caption'
    end
    compile

    # Article
    descriptor 'Article' do |desc|
      desc.text 'intro'
      desc.text 'headline', :maximum => 250
      desc.text 'body'
      desc.element 'picture', 'picture'
      desc.any 'author'
    end
    compile

    # Gallery
    descriptor 'Gallery' do |desc|
      desc.text 'title', :maximum => 250
      desc.text 'description'
      desc.array 'images', :items => ['Picture']
      desc.integer 'per_page', :minimum => 0, :maximum => 100
    end
    compile

    # Page
    descriptor 'Page'
    compile

    # ArticlePage
    descriptor 'ArticlePage' do |desc|
      desc.parent Elements::Types::Page.descriptor
      
      desc.element 'article', 'Article'
      desc.text 'footer', :default => @footer_text
    end
    compile

    # ReferencePage
    descriptor 'ReferencePage' do |desc|
      desc.parent Elements::Types::Page.descriptor

      desc.text 'title', :maximum => 250
      desc.text 'body'
      desc.array 'references' # TODO: specify allowed items
    end
    compile

    # MyReferences
    descriptor 'MyReferences' do |desc| 
      desc.parent Elements::Types::ReferencePage.descriptor
      
      desc.image 'teaser_image', :default => @image.id
      desc.resource 'attachment', :default => @resource.id
      desc.text 'footer', :default => @footer_text
    end
    compile
  end

  context 'defaults' do

    it 'should set default text' do
      Elements::Types::MyReferences.new.footer.should == @footer_text
    end

    it 'should not overwrite supplied values' do
      element = Elements::Types::MyReferences.new(:footer => 'My footer')
      element.footer.should == 'My footer'
    end

    it 'should set default image' do
      Elements::Types::MyReferences.new.teaser_image.should == @image
    end

    it 'should set default resource' do
      Elements::Types::MyReferences.new.attachment.should == @resource
    end

  end # context

  context 'massassignment' do

    it 'should assign attributes to essences' do
      attributes = { :title => 'My holiday', :description => 'Lorem Ipsum...' }
      gallery = Elements::Types::Gallery.new(attributes)

      gallery.title.should == attributes[:title]
      gallery.description.should == attributes[:description]
    end

    it 'should assign nested attributes to elements' do
      attributes = { 
        :article_attributes => { :headline => 'headline', :intro => 'Lorem Ipsum...' }, 
        :footer => '(c) 2011 John Doe' 
      }
      page = Elements::Types::ArticlePage.new(attributes)
      
      page.article.headline.should == attributes[:article_attributes][:headline]
      page.article.intro.should == attributes[:article_attributes][:intro]
      page.footer.should == attributes[:footer]
    end


    it 'should assign nested attributes to arrays' do
      attributes = {
        :title => 'My projects',
        :body  => 'Lorem Ipsum...',
        :references_attributes => [
          { :type => 'Gallery', :title => 'Redesign of zackboom.ch' },
          { :type => 'Gallery', :title => 'New RefineryCMS Events Extension' }
        ]
      }
      page = Elements::Types::ReferencePage.new(attributes)

      page.title.should == attributes[:title]
      page.body.should == attributes[:body]

      page.references.length.should == 2

      page.references.each_with_index do |gallery, i|
        gallery.should be_kind_of Elements::Types::Gallery
        gallery.title.should == attributes[:references_attributes][i][:title]
      end

    end

  end # context

  describe 'delegated reader' do
    let(:element) { Elements::Types::Gallery.new }


    it "should not build essence for nil-value" do
      element.integer_associations.should be_empty
      element.per_page = nil
      element.integer_associations.should be_empty
    end

    it "should not build essence for blank string" do
      element.text_associations.should be_empty
      element.title = ""
      element.text_associations.should be_empty
    end

  end

  context 'introspection' do

    describe "#property class method" do

      it 'should return ElementProperty or nil' do
        Elements::Types::Article.property('intro').should be_instance_of Elements::ElementProperty
        Elements::Types::Article.property('foo').should be_nil
      end

    end

    describe "#has_property? class method" do

      it 'should return true if property exists' do
        Elements::Types::Article.has_property?('intro').should == true
      end
      
      it 'should return false unless property exists' do
        Elements::Types::Article.has_property?('foo').should == false
      end
      
    end

    describe "#has_property? instance method" do

      it 'should return true if property exists' do
        Elements::Types::Article.new.has_property?('intro').should == true
      end
      
      it 'should return false unless property exists' do
        Elements::Types::Article.new.has_property?('foo').should == false
      end
      
    end

  end # context

  context 'serializable_hash' do

    before do
      @user = ::Refinery::User.create!(:username => 'testuser', :email => 'testuser@example.org', :password => 'example1234')
    end

    it 'should include all property values' do
      attributes = { :title => 'My holiday', :description => 'Lorem Ipsum...' }
      gallery = Elements::Types::Gallery.new(attributes)

      hash = gallery.serializable_hash

      hash['typename'].should == 'Gallery'
      hash['title'].should == attributes[:title]
      hash['description'].should == attributes[:description]
    end

    it 'should serialize any-types' do
      article = Elements::Types::Article.new :author => @user

      hash = article.serializable_hash

      hash['author']['value_data'].should == @user.serializable_hash
    end

  end

end

