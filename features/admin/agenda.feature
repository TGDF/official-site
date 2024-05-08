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

  Scenario: Admin User can see a list of agenda days
    Given there are some agenda days
      | label | date       |
      | Day1  | 2024-07-10 |
      | Day2  | 2024-07-11 |
    When I visit "/admin"
    And I click admin sidebar "Days" in "Agenda"
    Then I can see these items in table
      | text       |
      | Day1       |
      | Day2       |
      | 2024-07-10 |
      | 2024-07-11 |

  Scenario: Admin User can create a new agenda day
    When I visit "/admin"
    And I click admin sidebar "New Day" in "Agenda"
    And I fill the "agenda_day" form
      | field | value      |
      | label | Day1       |
    And I select options in the "agenda_day" form
      | field   | value |
      | date_1i | 2024  |
      | date_2i | 七月  |
      | date_3i | 10    |
    And I click "新增Agenda day"
    Then I can see these items in table
      | text       |
      | Day1       |
      | 2024-07-10 |

  Scenario: Admin User can edit an agenda day
    Given there are some agenda days
      | label | date       |
      | Day1  | 2024-07-10 |
      | Day2  | 2024-07-11 |
    When I visit "/admin"
    And I click admin sidebar "Days" in "Agenda"
    And I click "Edit" on row "Day1"
    And I fill the "agenda_day" form
      | field | value      |
      | label | Day3       |
    And I select options in the "agenda_day" form
      | field   | value |
      | date_1i | 2024  |
      | date_2i | 七月  |
      | date_3i | 12    |
    And I click "更新Agenda day"
    Then I can see these items in table
      | text       |
      | Day3       |
      | 2024-07-12 |

  Scenario: Admin User can delete an agenda day
    Given there are some agenda days
      | label | date       |
      | Day1  | 2024-07-10 |
      | Day2  | 2024-07-11 |
    When I visit "/admin"
    And I click admin sidebar "Days" in "Agenda"
    And I click "Destroy" on row "Day1"
    Then I should not see in the table
      | text       |
      | Day1       |
      | 2024-07-10 |

  Scenario: Admin User can see a list of agenda times
    Given there are some agenda days
      | label | date       |
      | Day1  | 2024-07-10 |
    Given there are some agenda times
      | label       | day  | order |
      | 08:00-09:00 | Day1 | 1     |
      | 09:00-10:00 | Day1 | 2     |
    When I visit "/admin"
    And I click admin sidebar "Times" in "Agenda"
    Then I can see these items in table
      | text              |
      | 08:00-09:00       |
      | 09:00-10:00       |
      | Day1 (2024-07-10) |

  Scenario: Admin User can create a new agenda time
    Given there are some agenda days
      | label | date       |
      | Day1  | 2024-07-10 |
    When I visit "/admin"
    And I click admin sidebar "New Time" in "Agenda"
    And I fill the "agenda_time" form
      | field | value      |
      | label | 08:00-09:00 |
    And I select options in the "agenda_time" form
      | field  | value             |
      | day_id | Day1 (2024-07-10) |
    And I click "新增Agenda time"
    Then I can see these items in table
      | text              |
      | 08:00-09:00       |
      | Day1 (2024-07-10) |

  Scenario: Admin User can edit an agenda time
    Given there are some agenda days
      | label | date       |
      | Day1  | 2024-07-10 |
    Given there are some agenda times
      | label       | day  | order |
      | 08:00-09:00 | Day1 | 1     |
      | 09:00-10:00 | Day1 | 2     |
    When I visit "/admin"
    And I click admin sidebar "Times" in "Agenda"
    And I click "Edit" on row "08:00-09:00"
    And I fill the "agenda_time" form
      | field | value      |
      | label | 10:00-11:00 |
    And I select options in the "agenda_time" form
      | field  | value             |
      | day_id | Day1 (2024-07-10) |
    And I click "更新Agenda time"
    Then I can see these items in table
      | text              |
      | 10:00-11:00       |
      | Day1 (2024-07-10) |

  Scenario: Admin User can delete an agenda time
    Given there are some agenda days
      | label | date       |
      | Day1  | 2024-07-10 |
    Given there are some agenda times
      | label       | day  | order |
      | 08:00-09:00 | Day1 | 1     |
      | 09:00-10:00 | Day1 | 2     |
    When I visit "/admin"
    And I click admin sidebar "Times" in "Agenda"
    And I click "Destroy" on row "08:00-09:00"
    Then I should not see in the table
      | text              |
      | 08:00-09:00       |
