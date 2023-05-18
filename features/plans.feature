@preview
Feature: Plans

  Background:
    Given there are some plans
      | name   | content                   | button   |
      | 自訂票 | <strong>強調顯示</strong> | 立即購票 |
    When I visit "/"

  Scenario: I can see "自訂票"
    Then I can see "自訂票"
