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

