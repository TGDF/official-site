Feature: Manage Speakers

  Background:
    Given an user logged as admin

  Scenario: Admin User can see a list of speakers
    Given there are some speakers
      | name | slug | title             | order | description     | avatar   |
      | John | john | Sr. Game Engineer | 1     | Awesome speaker | TGDF.png |
      | Jane | jane | Sr. Game Designer | 2     | Awesome speaker | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "Speaker"
    Then I can see these items in table
      | text   |
      | John   |
      | Jane   |

  Scenario: Admin User can create a speaker
    When I visit "/admin"
    And I click admin sidebar "New" in "Speaker"
    And I fill the "speaker" form
      | field       | value             |
      | name        | John              |
      | slug        | john              |
      | title       | Sr. Game Engineer |
      | order       | 1                 |
      | description | Awesome speaker   |
    And I attach files in the "speaker" form
      | field  | value    |
      | avatar | TGDF.png |
    And I click "新增Speaker" button
    Then I can see these items in table
      | text |
      | John |

  Scenario: Admin User can update a speaker
    Given there are some speakers
      | name | slug | title             | order | description     | avatar   |
      | Jane | john | Sr. Game Engineer | 1     | Awesome speaker | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "Speaker"
    And I click link "Edit"
    And I fill the "speaker" form
      | field       | value           |
      | name        | John            |
    And I click "更新Speaker" button
    Then I can see these items in table
      | text |
      | John |

  Scenario: Admin User can delete a speaker
    Given there are some speakers
      | name | slug | title             | order | description     | avatar   |
      | Jane | john | Sr. Game Engineer | 1     | Awesome speaker | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "Speaker"
    And I click link "Destroy"
    Then I should not see in the table
      | text |
      | Jane |
