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
