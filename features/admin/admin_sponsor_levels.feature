Feature: Manage Sponsor Levels

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

  Scenario: Admin User can edit sponsor level
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
