Feature: Manage Indie Space Options

  Background:
    Given an user logged as admin

  Scenario: Admin can update indie space description
    When I visit "/admin"
    And I click admin sidebar "Options" in "Indie Space"
    And I fill the "site" form
      | field                   | value                       |
      | indie_space_description | The Indie Space Description |
    And I click "更新Site" button
    And I visit "/indie_spaces"
    Then I can see "The Indie Space Description"
