Feature: Home Page

  Scenario: The home page will display latest news
    Given there are some news
      | title | content | slug | status    |
      | Demo  | A news  | demo | published |
    When I visit "/"
    Then I can see some news
      | title |
      | Demo  |

  Scenario: User can find a slide in page
    Given there are some slide in "home"
      | image    | language |
      | TGDF.png | zh-TW    |
    When  I visit "/"
    Then I can see the 1 slide in page
