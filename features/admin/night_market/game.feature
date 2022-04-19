Feature: Manage Night Market Games

  Background:
    Given an user logged as admin

  Scenario: Admin User can see a list of Night Market Games
    Given there are some night market games
      | name     | description | team       | thumbnail |
      | 遠古神話 | 範例遊戲    | 玄武工作室 | TGDF.png  |
      | 九日     | 範例遊戲    | 赤燭       | TGDF.png  |
    When I visit "/admin/night_market/games"
    Then I should see night market games are listed
      | name     |
      | 遠古神話 |
      | 九日     |

  Scenario: Admin User can add new Night Market Game
    When I visit "/admin/night_market/games/new"
    And I fill the Night Market Game form
      | field       | value                   |
      | name        | 遠古神話                |
      | description | 2015 年銘傳大學學生作品 |
      | team        | 玄武工作室              |
      | thumbnail   | TGDF.png                |
    And I click "新增Game" button
    Then I should see night market games are listed
      | name     |
      | 遠古神話 |

  Scenario: Admin User can edit Night Market Game
    Given there are some night market games
      | name     | description | team       | thumbnail |
      | 遠古神話 | 範例遊戲    | 玄武工作室 | TGDF.png  |
    When I visit "/admin/night_market/games"
    And I click link "遠古神話"
    And I fill the Night Market Game form
      | field | value  |
      | name  | 新紀元 |
    And I click "更新Game" button
    Then I should see night market games are listed
      | name   |
      | 新紀元 |

  Scenario: Admin User can delete Night Market Game
    Given there are some night market games
      | name     | description | team       | thumbnail |
      | 遠古神話 | 範例遊戲    | 玄武工作室 | TGDF.png  |
    When I visit "/admin/night_market/games"
    And I click "Destroy" on row "遠古神話"
    Then I should not see night market games are listed
      | name   |
      | 遠古神話 |
