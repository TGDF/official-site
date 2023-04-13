Feature: Tickets

  Background:
    When I visit "/"

  Scenario: I can see tickes information
    Then I can see "購票與售價"

  @streaming
  Scenario: I can see streaming information
    Then I can see "線上直播"
