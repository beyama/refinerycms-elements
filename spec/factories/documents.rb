FactoryGirl.define do

  factory :document, :class => Elements::Document do
  end

  factory :article_document, :parent => :document do
    elements { [ FactoryGirl.create(:article_document_element) ] }
  end

end
