Feature: Manage Blocks

Background:
    Given an user logged as admin

  Scenario: Admin User can see a list of blocks
    Given there are some block in "night_market"
      | content   | language | component_type |
      | Section 1 | zh-TW    | text           |
      | Section 2 | zh-TW    | text           |
    When I visit "/admin/news"
    And I click admin sidebar "List" in "Blocks"
    Then I can see these items in table
      | text      |
      | Section 1 |
      | Section 2 |

  Scenario: Admin User can add new block
    When I visit "/admin"
    And I click admin sidebar "New" in "Blocks"
    And I fill the Block form
      | field    | value        |
      | content  | Hello World  |
    And I select options in the "block" form
      | field    | value        |
      | language | 繁體中文     |
      | page     | Night Market |
      | component_type     | text         |
    And I click "新增Block" button
    Then I can see these items in table
      | text        |
      | Hello World |
