@elements @documents 
Feature: Elements
  In order to have documents on my website
  As an administrator
  I want to manage documents

  Background:
    Given I am a logged in refinery user
    And I have no documents
    And I have a couple of document types

  @documents-list @list
  Scenario: Documents List
   Given I have documents titled UniqueTitleOne, UniqueTitleTwo
   When I go to the list of documents
   Then I should see "UniqueTitleOne"
   And I should see "UniqueTitleTwo"

  @documents-list @search
  Scenario: Documents Search
   Given I have documents titled UniqueTitleOne, UniqueTitleTwo
   When I go to the list of documents
   And I fill in "search" with "one"
   And I press "Search"
   Then I should see "UniqueTitleOne"
   And I should not see "UniqueTitleTwo"

  @documents-valid @valid @javascript
  Scenario: Create Valid Document
    When I go to the list of documents
    And I follow "Add New Document"
    And I select "ArticleDocument" from "Type"
    And I fill in "Title" with "This is a test of the first string field"
    And I press "Save"
    Then I should see "'This is a test of the first string field' was successfully added."
    And I should have 1 document
    And I should have 1 element

  @documents-invalid @invalid @javascript
  Scenario: Create Invalid Document (without title)
    When I go to the list of documents
    And I follow "Add New Document"
    And I select "ArticleDocument" from "Type"
    And I press "Save"
    Then I should see "Elements title can't be blank"
    And I should have 0 documents
    And I should have 0 elements

  @documents-edit @edit @javascript
  Scenario: Edit Existing Element
    Given I have documents titled "A title"
    When I go to the list of documents
    And I follow the document edit link
    Then I fill in "Title" with "A different title"
    And I press "Save"
    Then I should see "'A different title' was successfully updated."
    And I should be on the list of documents
    And I should not see "A title"

  @documents-delete @delete
  Scenario: Delete Element
    Given I only have documents titled UniqueTitleOne
    When I go to the list of documents
    And I follow "Remove this document forever" within ".actions"
    Then I should see "'UniqueTitleOne' was successfully removed."
    And I should have 0 documents
    And I should have 0 elements
 
