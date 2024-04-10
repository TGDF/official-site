Feature: Manage News

  Background:
    Given an user logged as admin

  Scenario: Admin User can see a list of news
    Given there are some news
      | title  | slug   | content   | status    | thumbnail                    |
      | News 1 | news-1 | content 1 | published | TGDF.png |
      | News 2 | news-2 | content 2 | published | TGDF.png |
    When I visit "/admin"
    And I click admin sidebar "List" in "News"
    Then I can see these items in table
      | text      |
      | News 1    |
      | News 2    |

  Scenario: Admin User can create a news
    When I visit "/admin"
    And I click admin sidebar "New" in "News"
    And I fill the "news" form
      | field   | value     |
      | title   | News 3    |
      | slug    | news-3    |
      | content | content 3 |
    And I attach files in the "news" form
      | field     | value    |
      | thumbnail | TGDF.png |
    And I click "新增News"
    Then I can see these items in table
      | text      |
      | News 3    |

  Scenario: Admin User can update a news
    Given there are some news
      | title  | slug   | content   | status    | thumbnail |
      | News 1 | news-1 | content 1 | published | TGDF.png  |
      | News 2 | news-2 | content 2 | published | TGDF.png  |
    When I visit "/admin"
    And I click admin sidebar "List" in "News"
    And I click link "News 1"
    And I fill the "news" form
      | field   | value     |
      | title   | News 3    |
      | slug    | news-3    |
      | content | content 3 |
    And I click "更新News"
    Then I can see these items in table
      | text      |
      | News 3    |
      | News 2    |

  Scenario: Admin User can delete a news
    Given there are some news
      | title  | slug   | content   | status    | thumbnail |
      | News 1 | news-1 | content 1 | published | TGDF.png  |
      | News 2 | news-2 | content 2 | published | TGDF.png  |
    When I visit "/admin"
    And I click admin sidebar "List" in "News"
    And I click "Destroy" on row "News 1"
    Then I can see these items in table
      | text      |
      | News 2    |
