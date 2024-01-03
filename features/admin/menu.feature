Feature: Manage Menu

  Background:
    Given an user logged as admin

  Scenario: Admin can see the menus
    Given there have a "secondary" menu with
      | name     | link                | visible |
      | 立即購票 | https://example.com | yes     |
      | 會後問卷 | https://example.com | no      |
    When I visit "/admin"
    And I click admin sidebar "List" in "Menus"
    Then I can see these items in table
      | text     |
      | 立即購票 |
      | 會後問卷 |

  Scenario: Admin can create a new menu item
    When I visit "/admin"
    And I click admin sidebar "New" in "Menus"
    And I fill the "menu_item" form
      | field | value                |
      | name  | 立即購票             |
      | link  | https://example.com |
    And I click "新增Menu item" button
    Then I can see these items in table
      | text     |
      | 立即購票 |
