Feature: Admin manage Rooms

  Background:
    Given an user logged as admin

  Scenario: Admin can see all rooms
    Given there are some rooms
      | name   | order |
      | Room 1 | 1     |
      | Room 2 | 2     |
      | Room 3 | 3     |
      | Room 4 | 4     |
      | Room 5 | 5     |
    When I visit "/admin"
    And I click admin sidebar "Rooms" in "Agenda"
    Then I can see these items in table
      | text   |
      | Room 1 |
      | Room 2 |
      | Room 3 |
      | Room 4 |
      | Room 5 |

  Scenario: Admin can add a room
    Given there are some rooms
      | name | order |
      | R101 | 1     |
      | R102 | 2     |
    When I visit "/admin"
    And I click admin sidebar "New Room" in "Agenda"
    And I fill the "room" form
      | field | value |
      | name  | R103  |
      | order | 3     |
    And I click "新增Room"
    Then I can see these items in table
      | text |
      | R101 |
      | R102 |
      | R103 |

  Scenario: Admin can edit a room
    Given there are some rooms
      | name | order |
      | R101 | 1     |
      | R102 | 2     |
    When I visit "/admin"
    And I click admin sidebar "Rooms" in "Agenda"
    And I click "Edit" on row "R101"
    And I fill the "room" form
      | field | value |
      | name  | R103  |
      | order | 1     |
    And I click "更新Room"
    Then I can see these items in table
      | text |
      | R103 |
      | R102 |

  Scenario: Admin can delete a room
    Given there are some rooms
      | name | order |
      | R101 | 1     |
      | R102 | 2     |
    When I visit "/admin"
    And I click admin sidebar "Rooms" in "Agenda"
    And I click "Destroy" on row "R101"
    Then I can see these items in table
      | text |
      | R102 |
