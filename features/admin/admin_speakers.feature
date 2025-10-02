Feature: Admin manage speakers

  Background:
    Given an user logged as admin

  Scenario: Admin User can see a list of speakers
    Given there are some speakers
      | name      | slug      | title               | order | description     | avatar   |
      | Speaker1  | speaker1  | Sr. Game Engineer   | 1     | Awesome speaker | TGDF.png |
      | Speaker2  | speaker2  | Sr. Game Designer   | 2     | Awesome speaker | TGDF.png |
      | Speaker3  | speaker3  | Producer            | 3     | Awesome speaker | TGDF.png |
      | Speaker4  | speaker4  | Artist              | 4     | Awesome speaker | TGDF.png |
      | Speaker5  | speaker5  | Designer            | 5     | Awesome speaker | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "Speaker"
    Then I can see these items in table
      | text      |
      | Speaker1  |
      | Speaker2  |
      | Speaker3  |
      | Speaker4  |
      | Speaker5  |

  Scenario: Admin User can create a speaker
    When I visit "/admin"
    And I click admin sidebar "New" in "Speaker"
    And I fill the "speaker" form
      | field       | value             |
      | name        | Example           |
      | slug        | example           |
      | title       | Example Title     |
      | order       | 1                 |
      | description | Example Content   |
    And I attach files in the "speaker" form
      | field  | value    |
      | avatar | TGDF.png |
    And I click "新增Speaker" button
    Then I can see these items in table
      | text    |
      | Example |

  Scenario: Admin User can edit a speaker
    Given there are some speakers
      | name | slug | title | order | description     | avatar   |
      | OldName | oldname | Speaker | 1 | Old description | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "Speaker"
    And I click link "Edit"
    And I fill the "speaker" form
      | field | value           |
      | name  | New speaker Name |
    And I click "更新Speaker" button
    Then I can see these items in table
      | text             |
      | New speaker Name |

  Scenario: Admin User can destroy a speaker
    Given there are some speakers
      | name | slug | title | order | description     | avatar   |
      | ToDelete | todelete | Speaker | 1 | Old description | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "Speaker"
    And I click "Destroy" on row "ToDelete"
    Then I should not see in the table
      | text     |
      | ToDelete |
