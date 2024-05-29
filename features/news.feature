Feature: News

  Scenario: The news page will show the news
    Given there are some news
      | title       | content | slug        | status    |
      | Demo        | A news  | demo        | published |
      | Unpublished | A news  | unpublished | draft     |
    When I visit "/news"
    Then I can see some news
      | title |
      | Demo  |
    And I can't see the unpublished news
      | title       |
      | Unpublished |

  Scenario: The single news page will show the news content
    Given there are some news
      | title       | content | slug        | status    |
      | Demo        | A news  | demo        | published |
      | Unpublished | A news  | unpublished | draft     |
    When I visit "/news/demo"
    Then I can see "Demo"
    And I can see "A news"
