require 'spec_helper'

describe Elements::ElementDescriptor do

  def descriptor(attributes={})
    Elements::ElementDescriptor.new(attributes)
  end

  context 'validations' do

    it 'should only allow camelcase names' do
      descriptor(:name => 'Page').should be_valid
      descriptor(:name => 'Page12').should be_valid
      descriptor(:name => 'MyGallery').should be_valid

      descriptor(:name => 'my_gallery').should_not be_valid
      descriptor(:name => '12Gallery').should_not be_valid
      descriptor(:name => 'Gallery_23').should_not be_valid
    end

    it 'should disallow names from built-in types' do
      Elements::Types::BUILT_IN.each_pair do |name, _|
        descriptor(:name => name).should_not be_valid
      end
    end

    it 'name should be unique' do
      descriptor(:name => 'GalleryElement').save!
      descriptor(:name => 'GalleryElement').should_not be_valid
    end

  end

end
