Feature: Manage Partners

Background:
    Given an user logged as admin

  Scenario: Admin User can see the list of partner types
    Given there are some partner types
      | name     |
      | 合作夥伴 |
      | 新聞夥伴 |
    When I visit "/admin"
    And I click admin sidebar "Types" in "Partner"
    Then I can see these items in table
      | text     |
      | 合作夥伴 |

  Scenario: Admin User can see the list of partners
    Given there are some partner types
      | name   |
      | 合作夥伴 |
      | 新聞夥伴 |
    And there are some partners
      | name   | type    | logo     |
      | 資策會 | 合作夥伴 | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "Partner"
    Then I can see these items in table
      | text   |
      | 資策會 |

  Scenario: When add new partner type should see depcrecated message
    When I visit "/admin"
    And I click admin sidebar "New Type" in "Partner"
    Then I can see "This feature is deprecated, please use Sponsor instead."

  Scenario: When edit partner type should see depcrecated message
    Given there are some partner types
      | name     |
      | 合作夥伴 |
      | 新聞夥伴 |
    When I visit "/admin"
    And I click admin sidebar "Types" in "Partner"
    And I click "Edit" on row "合作夥伴"
    Then I can see "This feature is deprecated, please use Sponsor instead."

  Scenario: Admin User can delete partner type
    Given there are some partner types
      | name     |
      | 合作夥伴 |
    When I visit "/admin"
    And I click admin sidebar "Types" in "Partner"
    And I click "Destroy" on row "合作夥伴"
    Then I should not see in the table
      | text     |
      | 合作夥伴 |

  Scenario: When add new partner should see depcrecated message
    When I visit "/admin"
    Given there are some partner types
      | name     |
      | 合作夥伴 |
      | 新聞夥伴 |
    When I visit "/admin"
    And I click admin sidebar "New" in "Partner"
    Then I can see "This feature is deprecated, please use Sponsor instead."

  Scenario: When edit partner should see depcrecated message
    Given there are some partner types
      | name     |
      | 合作夥伴 |
      | 新聞夥伴 |
    And there are some partners
      | name   | type    | logo     |
      | 資策會 | 合作夥伴 | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "Partner"
    And I click "Edit" on row "資策會"
    Then I can see "This feature is deprecated, please use Sponsor instead."

  Scenario: Admin User can delete partner
    Given there are some partner types
      | name     |
      | 合作夥伴 |
      | 新聞夥伴 |
    And there are some partners
      | name   | type    | logo     |
      | 資策會 | 合作夥伴 | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "Partner"
    And I click "Destroy" on row "資策會"
    Then I should not see in the table
      | text   |
      | 資策會 |
