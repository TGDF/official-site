Feature: Home Page
  Scenario: The home page will display latest news
    Given There are some news
      | title | content | slug | status    |
      | Demo  | A news  | demo | published |
    When I visit "/"
    Then I can see some news
      | title |
      | Demo  |

