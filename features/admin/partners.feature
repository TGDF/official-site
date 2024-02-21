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

  Scenario: Admin User can add new partner type
    When I visit "/admin"
    And I click admin sidebar "New Type" in "Partner"
    And I fill the "partner_type" form
      | field | value    |
      | name  | 合作夥伴 |
    And I click "新增Partner type" button
    Then I can see these items in table
      | text     |
      | 合作夥伴 |

  Scenario: Admin User can edit partner type
    Given there are some partner types
      | name     |
      | 合作夥伴 |
      | 新聞夥伴 |
    When I visit "/admin"
    And I click admin sidebar "Types" in "Partner"
    And I click "Edit" on row "合作夥伴"
    And I fill the "partner_type" form
      | field | value    |
      | name  | 行銷夥伴 |
    And I click "更新Partner type" button
    Then I can see these items in table
      | text     |
      | 行銷夥伴 |
      | 新聞夥伴 |

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

  Scenario: Admin User can add new partner
    Given there are some partner types
      | name     |
      | 合作夥伴 |
      | 新聞夥伴 |
    When I visit "/admin"
    And I click admin sidebar "New" in "Partner"
    And I fill the "partner" form
      | field | value  |
      | name  | 資策會 |
    And I select options in the "partner" form
      | field   | value    |
      | type_id | 合作夥伴 |
    And I attach files in the "partner" form
      | field | value    |
      | logo  | TGDF.png |
    And I click "新增Partner" button
    Then I can see these items in table
      | text   |
      | 資策會 |

  Scenario: Admin User can edit partner
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
    And I fill the "partner" form
      | field | value              |
      | name  | 台北遊戲開發者論壇 |
    And I click "更新Partner" button
    Then I can see these items in table
      | text               |
      | 台北遊戲開發者論壇 |

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
