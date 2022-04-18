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
