if defined?(User)
  User.all.each do |user|
    if user.plugins.where(:name => 'refinerycms_elements').blank?
      user.plugins.create(:name => 'refinerycms_elements',
                          :position => (user.plugins.maximum(:position) || -1) +1)
    end
  end

  Elements::ElementBuilder.create :document_element do |e|
    e.title "Base of all Elements documents"
    e.text :title, :minimum => 1, :maximum => 250, :required => true
  end

  Elements::ElementBuilder.create :embedded_element do |e|
    e.title "Base of all embaddable elements"
  end

  Elements::ElementBuilder.create :page_element do |e|
    e.title "Base of all page elements"
  end

  Elements::ElementBuilder.create :picture do |e|
    e.parent :embedded_element
    e.title 'Picture element'
    e.image :image
    e.text :caption, :maximum => 250
  end

  Elements::ElementBuilder.create :gallery do |e|
    e.parent :embedded_element
    e.title 'Gallery element'
    e.array :pictures, :items => [:picture], :widget => 'PictureListView'
  end

  Elements::ElementBuilder.create :rich_text do |e|
    e.parent :embedded_element
    e.title 'Rich text element'
    e.text :text, :widget => 'EssenceRichTextView'
  end

  Elements::ElementBuilder.create :standard_page do |e|
    e.parent :page_element
    e.title 'Standard page'
    e.array :elements
  end

  Elements::ElementBuilder.create :gallery_document do |e|
    e.parent :document_element
    e.title 'Gallery document'
    
    e.text :description, :widget => 'EssenceRichTextView'
    e.array :pictures, :items => [:picture], :widget => 'PictureListView'
  end

end
