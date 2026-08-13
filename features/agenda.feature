Feature: Agenda
  Background:
    Given there are some speakers
      | name | slug | title             | order | description      | avatar   |
      | John | john | Sr. Game Engineer | 1     | Awesome Engineer | TGDF.png |
      | Jane | jane | Sr. Game Designer | 2     | Awesome Designer | TGDF.png |
    And there are some agenda rooms
      | name | order |
      | R0   | 1     |
    And there are some agenda days
      | label | date       |
      | Day1  | 2026-07-15 |
    And there are some agenda times
      | label              | day  | order | single |
      | Day1 - 15:00-16:00 | Day1 | 1     | true   |

  Scenario: I can tell two half-hour sessions apart within one slot
    Given "John" has a talk "Early Talk" at "Day1 - 15:00-16:00" from "2026-07-15 15:00" to "15:30"
    And "Jane" has a talk "Later Talk" at "Day1 - 15:00-16:00" from "2026-07-15 15:30" to "16:00"
    When I visit "/agenda"
    Then I can see "Day1 - 15:00-16:00"
    And I can see "Early Talk"
    And I can see "15:00 - 15:30"
    And I can see "Later Talk"
    And I can see "15:30 - 16:00"
