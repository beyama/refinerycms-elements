require 'spec_helper'
require File.expand_path('../../../../spec_helper', __FILE__)

describe Admin::Elements::ImageCropperWidget do
  has_widgets do |root|
    root << widget('admin/elements/image_cropper', 'image_cropper')
  end 

  before(:each) do
    ::Refinery::Image.destroy_all
    @image = ::Refinery::Image.create!(:image => File.new(File.expand_path('../../../../images/image.png', __FILE__)))
  end

  it 'responds to :show events' do
    response = trigger(:show, :image_cropper, :id => @image.id)
    data = JSON.parse(response.first)

    # View
    view = Capybara.string(data['view'])

    view.has_unchecked_field?('image_cropper_resizable').should be_true
    view.has_field?('width', :hidden => true).should be_true
    view.has_field?('height', :hidden => true).should be_true
    view.has_field?('height', :hidden => true).should be_true
    view.has_unchecked_field?('save_as_copy').should be_true

    # Data
    data['image_height'].should == @image.height
    data['image_width'].should == @image.width
    data['original'].should == @image.url
  end

  it 'responds to :crop events with overwritten image' do
    count = ::Refinery::Image.count

    trigger(:crop, :image_cropper, :id => @image.id, :x => 0, :y => 0, :w => 10, :h => 8)

    @image.reload
    @image.width.should == 10
    @image.height.should == 8

    ::Refinery::Image.count.should == count
  end

  it 'responds to :crop events with copied image' do
    count = ::Refinery::Image.count

    response = trigger(:crop, :image_cropper, :id => @image.id, :x => 0, :y => 0, :w => 10, :h => 8, :save_as_copy => true)
    data = JSON.parse(response.first)

    new_image = ::Refinery::Image.find(data['id'])
    new_image.width.should == 10
    new_image.height.should == 8

    @image.should_not == new_image

    ::Refinery::Image.count.should == count + 1
  end
end
