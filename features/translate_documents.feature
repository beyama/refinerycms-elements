@elements @documents @documents-translate @i18n @javascript
Feature: Translate Documents
  In order to make the content on my website accessible in many countries
  As a translator
  I want to translate documents

  Background:
    Given A Refinery user exists
    And I am a logged in refinery user
    And I have frontend locales en, de
    And I have a couple of document types
    And I have documents titled Gallery, Events

  Scenario: Create document in more than one translation
    When I go to the list of documents
    And I follow "Add New Document"
    And I select "ArticleDocument" from "Type"
    And I fill in "Title" with "Holiday pictures"
    And I select "de" from "Locale"
    And I fill in "Title" with "Urlaubsfotos"
    And I press "Save"
    Then I should see "'Holiday pictures' was successfully added."
    And I should have 3 documents
    And I should have 4 elements

  Scenario: Add translation to existing document
    When I go to the document titled Events
    And I select "de" from "Locale"
    And I fill in "Title" with "Veranstaltungen"
    And I press "Save"
    Then I should see "'Events' was successfully updated."
    And I should have 2 documents
    And I should have 3 elements

