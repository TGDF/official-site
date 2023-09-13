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


