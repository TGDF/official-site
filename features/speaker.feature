Feature: Speaker
  Background:
    Given there are some speakers
      | name | slug | title             | order | description      | avatar   |
      | John | john | Sr. Game Engineer | 1     | Awesome Engineer | TGDF.png |
      | Jane | jane | Sr. Game Designer | 2     | Awesome Designer | TGDF.png |

  Scenario: I can see a list of speakers
    When I visit "/"
    And I click "講者" in menu
    Then I can see "John"
    And I can see "Jane"

  Scenario: I can see a speaker detail
    When I visit "/"
    And I click "講者" in menu
    And I click "John"
    Then I can see "John"
    And I can see "Sr. Game Engineer"
    And I can see "Awesome Engineer"
