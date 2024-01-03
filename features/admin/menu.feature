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
