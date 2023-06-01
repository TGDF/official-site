Feature: Manage Plans

Background:
    Given an user logged as admin

  Scenario: Admin User can see a list of plans
    Given there are some plans
      | name   | content                   | button   |
      | 自訂票 | <strong>強調顯示</strong> | 立即預留 |
      | 學生票 | <strong>強調顯示</strong> | 立即預留 |
    When I visit "/admin"
    And I click admin sidebar "List" in "Plans"
    Then I can see these items in table
      | text   |
      | 自訂票 |
      | 學生票 |

  Scenario: Admin User can add new plan
    When I visit "/admin"
    And I click admin sidebar "New" in "Plans"
    And I fill the "plan" form
      | field         | value            |
      | name          | 學生票           |
      | content       | 測試內容         |
      | button_label  | 立即購票         |
      | button_target | https://tgdf.tw/ |
    And I click "新增Plan" button
    Then I can see these items in table
      | text   |
      | 學生票 |

  Scenario: Admin User can edit plan
    Given there are some plans
      | name   | content                   | button   |
      | 自訂票 | <strong>強調顯示</strong> | 立即預留 |
    When I visit "/admin"
    And I click admin sidebar "List" in "Plans"
    And I click link "Edit"
    And I fill the "plan" form
      | field | value  |
      | name  | 學生票 |
    And I click "更新Plan" button
    Then I can see these items in table
      | text   |
      | 學生票 |

  Scenario: Admin User can delete plan
    Given there are some plans
      | name   | content                   | button   |
      | 自訂票 | <strong>強調顯示</strong> | 立即預留 |
    When I visit "/admin"
    And I click admin sidebar "List" in "Plans"
    And I click "Destroy" on row "自訂票"
    Then I should not see in the table
      | text   |
      | 自訂票 |
