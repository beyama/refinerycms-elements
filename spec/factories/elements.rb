FactoryGirl.define do

  factory :article_document_element, :class => 'Elements::Types::ArticleDocument' do
    sequence(:title) {|n| "Document title #{n}" }
    locale "en"
  end

end
