Feature: Night Market

  Background:
    Given there are some night market games
      | name     | description | team       | website             | video                                       | thumbnail |
      | 遠古神話 | 範例遊戲    | 玄武工作室 | https://basaltic.tw | https://www.youtube.com/watch?v=QBYZAZlH9cw | TGDF.png  |
      | 九日     | 範例遊戲    | 赤燭       |                     |                                             | TGDF.png  |

  @night_market_enabled
  Scenario: User can see the games listed on page
    When  I visit "/"
    And I click "遊戲夜市" in menu
    Then I can see the game in the page
      | text     |
      | 遠古神話 |
      | 九日     |

  @night_market_enabled
  Scenario: User can find a team button
    When  I visit "/"
    And I click "遊戲夜市" in menu
    Then I can see the game developer in the page
      | name       | link                |
      | 玄武工作室 | https://basaltic.tw |
      | 赤燭       |                     |

  @night_market_enabled
  Scenario: User can find a video button
    When  I visit "/"
    And I click "Night Market" in menu
    Then I can see the game video in the page
      | name     | video                                       |
      | 遠古神話 | https://www.youtube.com/watch?v=QBYZAZlH9cw |

  @night_market_enabled
  Scenario: User can find a slide in page
    Given there are some slide in "night_market"
      | image    | language |
      | TGDF.png | zh-TW    |
    When  I visit "/"
    And I click "遊戲夜市" in menu
    Then I can see the 1 slide in page

  @night_market_enabled
  Scenario: User can find a description in page
    Given there are some block in "night_market"
      | content     | language | component_type |
      | Hello World | zh-TW    | text           |
    When  I visit "/"
    And I click "遊戲夜市" in menu
    Then I can see the text block with "Hello World"
    
  @night_market_enabled
  Scenario: The button text in menu should have en translation
    When  I visit "/en" 
    And I click "Nightmarket Festival" in menu
    Then I can see the text block with "Hello World"
