Feature: Admin Sliders Management

  Background:
    Given an user logged as admin

  Scenario: Admin can see a list of sliders
    Given there are some slide in "home"
      | image    | language | interval |
      | TGDF.png | zh-TW    | 5000     |
      | TGDF.png | zh-TW    | 5000     |
      | TGDF.png | zh-TW    | 5000     |
      | TGDF.png | zh-TW    | 5000     |
      | TGDF.png | zh-TW    | 5000     |
    When I visit "/admin"
    And I click admin sidebar "List" in "Slider"
    Then I can see these items in table
      | text     |
      | 繁體中文 |

  Scenario: Admin can add a new slider
    When I visit "/admin"
    And I click admin sidebar "New" in "Slider"
    And I attach files in the "slider" form
      | field | value    |
      | image | TGDF.png |
    And I select options in the "slider" form
      | field    | value    |
      | language | 繁體中文 |
      | page     | 首頁     |
    And I click "新增Slider" button
    Then I can see these items in table
      | text     |
      | 繁體中文 |

  Scenario: Admin can edit a slider
    Given there are some slide in "home"
      | image    | language | interval |
      | TGDF.png | zh-TW    | 5000     |
    When I visit "/admin"
    And I click admin sidebar "List" in "Slider"
    And I click link "Edit"
    And I select options in the "slider" form
      | field    | value   |
      | language | English |
      | page     | 首頁    |
    And I click "更新Slider" button
    Then I can see these items in table
      | text    |
      | English |

  Scenario: Admin can delete a slider
    Given there are some slide in "home"
      | image    | language | interval |
      | TGDF.png | zh-TW    | 5000     |
      | TGDF.png | en       | 5000     |
    When I visit "/admin"
    And I click admin sidebar "List" in "Slider"
    And I click "Destroy" on row "繁體中文"
    Then I should not see in the table
      | text     |
      | 繁體中文 |
