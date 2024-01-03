Feature: Menu
  Scenario: The menu is visible
    When I visit "/"
    Then I can see "首頁" in menu
    And I can see "新聞" in menu
    And I can see "議程表" in menu
    And I can see "合作夥伴" in menu
    And I can see "活動守則" in menu

  @cfp_mode
  Scenario: The menu is hidden when CFP mode enabled
    When  I visit "/"
    Then I can see "活動守則" in menu
    And I can not see "首頁" in menu
    And I can not see "新聞" in menu
    And I can not see "議程表" in menu
    And I can not see "合作夥伴" in menu

  Scenario: The secondary menu can be customize
    Given there have a "secondary" menu with
      | name     | link                | visible |
      | 立即購票 | https://example.com | yes     |
      | 會後問卷 | https://example.com | no      |
    When I visit "/"
    Then I can see "立即購票" in menu
    And I can not see "會後問卷" in menu
