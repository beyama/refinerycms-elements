require 'spec_helper'
require File.expand_path('../../../spec_helper', __FILE__)

describe Elements::Document do

  include Elements::SpecHelper

  before(:all) do
    Elements::Types.reset!
    Elements::ElementDescriptor.destroy_all

    descriptor 'DocumentElement' do |desc|
      desc.text 'title'
    end
    compile
  end

  context 'massassignment' do

    before(:each) do
      @element_attributes = [
        { :type => 'DocumentElement', :locale => 'en', :title => 'Document' },
        { :type => 'DocumentElement', :locale => 'de', :title => 'Dokument' }
      ]
    end

    it 'should assign attributes on create' do
      @doc = Elements::Document.create(:elements_attributes => @element_attributes)
      @doc.elements.count.should == 2

      element = @doc.elements.find_by_locale 'en'
      element.title.should == 'Document'

      element = @doc.elements.find_by_locale 'de'
      element.title.should == 'Dokument'
    end

    it 'should assign attributes on update' do
      @doc = Elements::Document.create(:elements_attributes => @element_attributes)

      element = @doc.elements.find_by_locale 'en'
      @doc.update_attributes(:elements_attributes => { 
        :id => element.id, 
        :title => 'Updated document'
      })
      element.reload
      element.title.should == 'Updated document'
    end

    it 'should destroy element by setting the _destroy attribute' do
      @doc = Elements::Document.create(:elements_attributes => @element_attributes)

      element = @doc.elements.find_by_locale 'en'
      @doc.update_attributes(:elements_attributes => { 
        :id => element.id, 
        :_destroy => true
      })
      @doc.elements(true).size.should == 1
    end

  end

end
