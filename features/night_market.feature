Feature: Night Market

  Background:
    Given there are some night market games
      | name     | description | team       | thumbnail |
      | 遠古神話 | 範例遊戲    | 玄武工作室 | TGDF.png  |
      | 九日     | 範例遊戲    | 赤燭       | TGDF.png  |

  @night_market_enabled
  Scenario: User can see the games listed on page
    When  I visit "/"
    And I click "Night Market" in menu
    Then I can see the game in the page
      | text     |
      | 遠古神話 |
      | 九日     |

