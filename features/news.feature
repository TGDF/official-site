Feature: News
  Background:
    Given there are some news
      | title       | content | slug        | status    |
      | Demo        | A news  | demo        | published |
      | Unpublished | A news  | unpublished | draft     |

  Scenario: The news page will show the news
    When I visit "/"
    And I click "新聞" in menu
    Then I can see some news
      | title |
      | Demo  |
    And I can't see the unpublished news
      | title       |
      | Unpublished |

  Scenario: The single news page will show the news content
    When I visit "/"
    And I click "新聞" in menu
    And I click "Demo"
    Then I can see "Demo"
    And I can see "A news"
