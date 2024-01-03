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

  Scenario: Admin can edit a menu item
    Given there have a "secondary" menu with
      | name     | link                | visible |
      | 立即購票 | https://example.com | yes     |
    When I visit "/admin"
    And I click admin sidebar "List" in "Menus"
    And I click link "Edit"
    And I fill the "menu_item" form
      | field | value                |
      | name  | 會後問卷             |
      | link  | https://example.com |
    And I click "更新Menu item" button
    Then I can see these items in table
      | text     |
      | 會後問卷 |


  Scenario: Admin can delete a menu item
    Given there have a "secondary" menu with
      | name     | link                | visible |
      | 立即購票 | https://example.com | yes     |
    When I visit "/admin"
    And I click admin sidebar "List" in "Menus"
    And I click "Destroy" on row "立即購票"
    Then I should not see in the table
      | text     |
      | 立即購票 |
