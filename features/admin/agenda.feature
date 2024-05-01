Feature: Manage Agenda

  Background:
    Given an user logged as admin

  Scenario: Admin User can see a list of agenda tags
    Given there are some agenda tags
      | name        |
      | Programming |
    When I visit "/admin"
    And I click admin sidebar "Tags" in "Agenda"
    Then I can see these items in table
      | text        |
      | Programming |

  Scenario: Admin User can create a new agenda tag
    When I visit "/admin"
    And I click admin sidebar "New Tag" in "Agenda"
    And I fill the "agenda_tag" form
      | field         | value            |
      | name          | Music            |
    And I click "新增Agenda tag"
    Then I can see these items in table
      | text  |
      | Music |

  Scenario: Admin User can edit an agenda tag
    Given there are some agenda tags
      | name        |
      | Programming |
    When I visit "/admin"
    And I click admin sidebar "Tags" in "Agenda"
    And I click link "Edit"
    And I fill the "agenda_tag" form
      | field         | value            |
      | name          | Music            |
    And I click "更新Agenda tag"
    Then I can see these items in table
      | text  |
      | Music |

  Scenario: Admin User can delete an agenda tag
    Given there are some agenda tags
      | name        |
      | Programming |
    When I visit "/admin"
    And I click admin sidebar "Tags" in "Agenda"
    And I click "Destroy" on row "Programming"
    Then I should not see in the table
      | text        |
      | Programming |

  Scenario: Admin User can see a list of agenda rooms
    Given there are some agenda rooms
      | name   | order |
      | Room 1 | 1     |
      | Room 2 | 2     |
    When I visit "/admin"
    And I click admin sidebar "Rooms" in "Agenda"
    Then I can see these items in table
      | text   |
      | Room 1 |
      | Room 2 |

  Scenario: Admin User can create a new agenda room
    When I visit "/admin"
    And I click admin sidebar "New Room" in "Agenda"
    And I fill the "room" form
      | field         | value            |
      | name          | Room 3           |
      | order         | 3                |
    And I click "新增Room"
    Then I can see these items in table
      | text   |
      | Room 3 |

  Scenario: Admin User can edit an agenda room
    Given there are some agenda rooms
      | name   | order |
      | Room 1 | 1     |
      | Room 2 | 2     |
    When I visit "/admin"
    And I click admin sidebar "Rooms" in "Agenda"
    And I click "Edit" on row "Room 1"
    And I fill the "room" form
      | field         | value            |
      | name          | Room 3           |
      | order         | 3                |
    And I click "更新Room"
    Then I can see these items in table
      | text   |
      | Room 3 |

  Scenario: Admin User can delete an agenda room
    Given there are some agenda rooms
      | name   | order |
      | Room 1 | 1     |
      | Room 2 | 2     |
    When I visit "/admin"
    And I click admin sidebar "Rooms" in "Agenda"
    And I click "Destroy" on row "Room 1"
    Then I should not see in the table
      | text   |
      | Room 1 |
