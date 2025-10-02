Feature: Admin manage Sponsors

  Background:
    Given an user logged as admin

  Scenario: Admin can see the list of sponsors
    Given there are some sponsor levels
      | name   |
      | 白金級 |
    And there are some sponsors
      | name       | level  | logo     |
      | Sponsor 1  | 白金級 | TGDF.png |
      | Sponsor 2  | 白金級 | TGDF.png |
      | Sponsor 3  | 白金級 | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "Sponsor"
    Then I can see these items in table
      | text      |
      | Sponsor 1 |
      | Sponsor 2 |
      | Sponsor 3 |

  Scenario: Admin can add new sponsor
    Given there are some sponsor levels
      | name   |
      | 白金級 |
    When I visit "/admin"
    And I click admin sidebar "New" in "Sponsor"
    And I fill the "sponsor" form
      | field | value   |
      | name  | Example |
    And I select options in the "sponsor" form
      | field    | value  |
      | level_id | 白金級 |
    And I attach files in the "sponsor" form
      | field | value    |
      | logo  | TGDF.png |
    And I click "新增Sponsor" button
    Then I can see these items in table
      | text    |
      | Example |

  Scenario: Admin can edit sponsor
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
      | field | value             |
      | name  | New sponsor Name |
    And I click "更新Sponsor" button
    Then I can see these items in table
      | text              |
      | New sponsor Name  |

  Scenario: Admin can destroy sponsor
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