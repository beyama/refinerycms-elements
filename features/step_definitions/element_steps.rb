require File.expand_path('../../../spec/spec_helper.rb', __FILE__)

include Elements::SpecHelper

Given /^I have no documents$/ do
  Elements::Document.delete_all
end

Given /^I have a couple of document types$/ do
  Elements::ElementDescriptor.delete_all

  doc = Elements::ElementDescriptor.new :name => 'DocumentElement'
  doc.properties.build(:name => 'title', :title => 'Title', :typename => 'Text', :minimum => 1, :maximum => 250, :required => true, :position => 0)
  doc.save!

  descriptor 'ArticleDocument' do |desc|
    desc.parent doc
  end
  compile
end

Given /^I (only )?have documents titled "?([^\"]*)"?$/ do |only, titles|
  Elements::Document.delete_all if only
  titles.split(', ').each do |title|
    Elements::Document.create(:elements_attributes => [{ :type => 'ArticleDocument', :locale => 'en', :title => title }])
  end
end

# admin.js removes action link title, so 
# I follow "Edit this Document"
# doesn't work
When /^I follow the document edit link$/ do
  find(".actions a[tooltip^=Edit]").click
end

Then /^I should have (\d+) documents?$/ do |count|
  Elements::Document.count.should == count.to_i
end

Then /^I should have (\d+) elements?$/ do |count|
  Elements::Element.count.should == count.to_i
end
