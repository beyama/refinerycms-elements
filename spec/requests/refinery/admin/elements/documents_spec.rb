require "spec_helper"

# FIXME: This should be done automatically. What is the problem?
Refinery::Testing.load_factories 

module Refinery
  module Admin
    module Elements

      describe "Documents" do
        login_refinery_user
        create_and_compile_some_document_desciptors

        context "when no documents" do
          it "invites to create one" do
            visit refinery.admin_elements_documents_path
            page.should have_content(%q{There are no documents yet. Click "Add new document" to add your first document.})
          end
        end

        describe "search" do
          before(:each) do
            ['Unique title one', 'Unique title two'].each do |title|
              doc = FactoryGirl.create :article_document
              doc.translation.title = title
              doc.translation.save
            end
          end

          it "shows only documents with matching title" do
            visit refinery.admin_elements_documents_path

            fill_in 'search', :with => 'title two'
            click_button 'Search'

            page.should have_content('Unique title two')
            page.should_not have_content('Unique title one')
          end
        end

        describe "action links" do
          it "shows add new document link" do
            visit refinery.admin_elements_documents_path

            within "#actions" do
              page.should have_content("Add new document")
              page.should have_selector("a[href='/refinery/elements/documents/new']")
            end
          end

          context "when no documents" do
            it "doesn't show reorder documents link" do
              visit refinery.admin_elements_documents_path

              within "#actions" do
                page.should have_no_content("Reorder documents")
                page.should have_no_selector("a[href='/refinery/elements/documents']")
              end
            end
          end

          context "when some documents exist" do
            before(:each) { 2.times { FactoryGirl.create :article_document } }

            it "shows reorder documents link" do
              visit refinery.admin_elements_documents_path

              within "#actions" do
                page.should have_content("Reorder documents")
                page.should have_selector("a[href='/refinery/elements/documents']")
              end
            end
          end

        end

        describe "new/create" do
          context "when valid" do

            it "allows to create document", :js => true do
              visit refinery.admin_elements_documents_path

              click_link "Add new document"

              select "ArticleDocument", :from => "Type"
              fill_in "Title", :with => "My first document"
              click_button "Save"

              page.should have_content("'My first document' was successfully added.")

              page.body.should =~ /Remove this document forever/
              page.body.should =~ /Edit this document/
              page.body.should =~ %r{/refinery/elements/documents/#{::Elements::Document.first.id}/edit}

              ::Elements::Document.count.should == 1
            end
          end

          context "when invalid" do
            it "shows an error message", :js => true do
              visit refinery.admin_elements_documents_path

              click_link "Add new document"

              select "ArticleDocument", :from => "Type"
              click_button "Save"

              page.should have_content("There were problems with the following fields")

              ::Elements::Document.count.should == 0
            end
          end
        end

        describe "edit/update" do
          before(:each) do
            doc = FactoryGirl.create :article_document
            doc.translation.title = "Update me"
            doc.translation.save
          end

          it "updates document", :js => true do
            visit refinery.admin_elements_documents_path

            page.should have_content("Update me")

            find(:xpath, "//a[@tooltip='Edit this document']").click

            fill_in "Title", :with => "Updated"
            click_button "Save"

            page.should have_content("'Updated' was successfully updated.")
          end
        end

        describe "destroy" do
          before(:each) do
            doc = FactoryGirl.create :article_document
            doc.translation.title = "Delete me"
            doc.translation.save
          end

          it "deletes document" do
            visit refinery.admin_elements_documents_path

            click_link "Remove this document forever"

            page.should have_content("'Delete me' was successfully removed.")

            ::Elements::Document.count.should == 0
          end
        end

        context "without translations" do

          describe "index" do
            before(:each) do
              FactoryGirl.create :article_document 
            end

            it "shows no locale flag for document" do
              visit refinery.admin_elements_documents_path

              d = ::Elements::Document.first
              within "#document_#{d.id}" do
                 page.should_not have_css("img[src='/assets/refinery/icons/flags/en.png']")
              end
            end
          end

          describe "new/edit" do
            it "shows no locale selectbox for document", :js => true do
              visit refinery.new_admin_elements_document_path

              within ".elements-editor-header" do
                page.should_not have_css(".localeChooser")
              end
            end
          end

        end

        context "with translations" do
          before(:each) do
            Refinery::I18n.stub(:frontend_locales).and_return([:en, :de])
          end

          describe "index" do
            before(:each) do
              FactoryGirl.create :article_document 
            end

            it "shows locale flag for document" do
              visit refinery.admin_elements_documents_path

              d = ::Elements::Document.first
              within "#document_#{d.id}" do
                 page.should have_css("img[src='/assets/refinery/icons/flags/en.png']")
              end
            end
          end

          describe "new/create" do
            it "allows to create document", :js => true do
              visit refinery.admin_elements_documents_path

              click_link "Add new document"

              within ".elements-editor-header" do
                page.should have_css(".localeChooser")
              end

              select "ArticleDocument", :from => "Type"
              fill_in "Title", :with => "My first document"

              select "de", :from => "Locale"
              fill_in "Title", :with => "Mein erstes Dokument"

              click_button "Save"

              ::Elements::Document.count.should == 1
              ::Elements::Element.count.should == 2
            end
          end

          describe "edit/update" do
            before(:each) do
              FactoryGirl.create :article_document 
            end

            it "allows to add translation to existing document", :js => true do
              visit refinery.edit_admin_elements_document_path(::Elements::Document.first) 

              select "de", :from => "Locale"
              fill_in "Title", :with => "Mein erstes Dokument"

              click_button "Save"

              ::Elements::Document.count.should == 1
              ::Elements::Element.count.should == 2
            end
          end

        end

      end

    end
  end
end
