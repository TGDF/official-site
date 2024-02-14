Feature: Manage Sponsors

Background:
    Given an user logged as admin

  Scenario: Admin User can see the list of sponsor levels
    Given there are some sponsor levels
      | name   |
      | 白金級 |
      | 鑽石級 |
    When I visit "/admin"
    And I click admin sidebar "Levels" in "Sponsor"
    Then I can see these items in table
      | text   |
      | 白金級 |

  Scenario: Admin User can see the list of sponsor
    Given there are some sponsor levels
      | name   |
      | 白金級 |
      | 鑽石級 |
    And there are some sponsors
      | name     | level  | logo     |
      | 雷亞遊戲 | 白金級 | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "Sponsor"
    Then I can see these items in table
      | text     |
      | 雷亞遊戲 |

  Scenario: Admin User can add new sponsor level
    When I visit "/admin"
    And I click admin sidebar "New Level" in "Sponsor"
    And I fill the "sponsor_level" form
      | field | value  |
      | name  | 白金級 |
    And I click "新增Sponsor level" button
    Then I can see these items in table
      | text   |
      | 白金級 |

  Scenario: Admin User can add edit sponsor level
    Given there are some sponsor levels
      | name   |
      | 白金級 |
      | 黃金級 |
    When I visit "/admin"
    And I click admin sidebar "Levels" in "Sponsor"
    And I click "Edit" on row "白金級"
    And I fill the "sponsor_level" form
      | field | value  |
      | name  | 鑽石級 |
    And I click "更新Sponsor level" button
    Then I can see these items in table
      | text   |
      | 鑽石級 |
      | 黃金級 |

  Scenario: Admin User can delete sponsor level
    Given there are some sponsor levels
      | name   |
      | 白金級 |
    When I visit "/admin"
    And I click admin sidebar "Levels" in "Sponsor"
    And I click "Destroy" on row "白金級"
    Then I should not see in the table
      | text   |
      | 白金級 |

  Scenario: Admin User can add new sponsor
    Given there are some sponsor levels
      | name   |
      | 白金級 |
    When I visit "/admin"
    And I click admin sidebar "New" in "Sponsor"
    And I fill the "sponsor" form
      | field | value    |
      | name  | 雷亞遊戲 |
    And I select options in the "sponsor" form
      | field    | value  |
      | level_id | 白金級 |
    And I attach files in the "sponsor" form
      | field     | value    |
      | logo      | TGDF.png |
    And I click "新增Sponsor" button
    Then I can see these items in table
      | text     |
      | 雷亞遊戲 |

  Scenario: Admin User can edit sponsor
    Given there are some sponsor levels
      | name   |
      | 白金級 |
      | 黃金級 |
    And there are some sponsors
      | name     | level  | logo     |
      | 雷亞遊戲 | 白金級 | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "Sponsor"
    And I click "Edit" on row "雷亞遊戲"
    And I fill the "sponsor" form
      | field | value              |
      | name  | 台北遊戲開發者論壇 |
    And I click "更新Sponsor" button
    Then I can see these items in table
      | text               |
      | 台北遊戲開發者論壇 |

  Scenario: Admin User can delete sponsor
    Given there are some sponsor levels
      | name   |
      | 白金級 |
    And there are some sponsors
      | name     | level  | logo     |
      | 雷亞遊戲 | 白金級 | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "Sponsor"
    And I click "Destroy" on row "雷亞遊戲"
    Then I should not see in the table
      | text     |
      | 雷亞遊戲 |
