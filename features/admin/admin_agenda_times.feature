@apartment
Feature: Manage Agenda Times in Admin

  Background:
    Given an user logged as admin

  Scenario: Admin can see all agenda times
    Given there are some agenda days
      | label | date       |
      | Day1  | 2024-07-10 |
    Given there are some agenda times
      | label   | day  | order |
      | Time 1  | Day1 | 1     |
      | Time 2  | Day1 | 2     |
      | Time 3  | Day1 | 3     |
      | Time 4  | Day1 | 4     |
      | Time 5  | Day1 | 5     |
    When I visit "/admin"
    And I click admin sidebar "Times" in "Agenda"
    Then I can see these items in table
      | text   |
      | Time 1 |
      | Time 2 |
      | Time 3 |
      | Time 4 |
      | Time 5 |

  Scenario: Admin can create a new agenda time
    Given there are some agenda days
      | label | date       |
      | Day1  | 2024-07-10 |
    When I visit "/admin"
    And I click admin sidebar "New Time" in "Agenda"
    And I fill the "agenda_time" form
      | field | value        |
      | label | Example Time |
    And I select options in the "agenda_time" form
      | field  | value             |
      | day_id | Day1 (2024-07-10) |
    And I click "新增Agenda time"
    Then I can see these items in table
      | text        |
      | Example Time |
      | Day1        |

  Scenario: Admin can edit an agenda time
    Given there are some agenda days
      | label | date       |
      | Day1  | 2024-07-10 |
    Given there are some agenda times
      | label      | day  | order |
      | Old Label  | Day1 | 1     |
    When I visit "/admin"
    And I click admin sidebar "Times" in "Agenda"
    And I click "Edit" on row "Old Label"
    And I fill the "agenda_time" form
      | field | value               |
      | label | New agenda_time Label |
    And I select options in the "agenda_time" form
      | field  | value             |
      | day_id | Day1 (2024-07-10) |
    And I click "更新Agenda time"
    Then I can see these items in table
      | text                 |
      | New agenda_time Label |
      | Day1                 |

  Scenario: Admin can destroy an agenda time
    Given there are some agenda days
      | label | date       |
      | Day1  | 2024-07-10 |
    Given there are some agenda times
      | label      | day  | order |
      | To be gone | Day1 | 1     |
    When I visit "/admin"
    And I click admin sidebar "Times" in "Agenda"
    And I click "Destroy" on row "To be gone"
    Then I should not see in the table
      | text        |
      | To be gone  |
