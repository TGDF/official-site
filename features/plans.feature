@preview
Feature: Plans

  Background:
    Given there are some plans
      | name   | content                   | button_label |
      | 自訂票 | <strong>強調顯示</strong> | 立即預留     |
    When I visit "/"

  Scenario: I can see "自訂票"
    Then I can see "自訂票"
    And I can see "強調顯示"
    And I can see "立即預留"
