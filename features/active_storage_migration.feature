# frozen_string_literal: true

Feature: ActiveStorage Migration
  As a system administrator
  I want to migrate from CarrierWave to ActiveStorage
  So that I can use Rails native file storage

  # =============================================================================
  # Speaker - avatar
  # =============================================================================

  @active_storage_read
  Scenario: Speaker avatar served from CarrierWave when read disabled
    Given there are some speakers
      | name | slug | title             | order | description     | avatar   |
      | John | john | Sr. Game Engineer | 1     | Awesome speaker | TGDF.png |
    And ActiveStorage read is disabled
    When I visit "/"
    And I click "講者" in menu
    Then I can see speaker "John" with CarrierWave avatar

  @active_storage_read
  Scenario: Speaker avatar served from ActiveStorage when read enabled
    Given there are some speakers
      | name | slug | title             | order | description     | avatar   |
      | John | john | Sr. Game Engineer | 1     | Awesome speaker | TGDF.png |
    And ActiveStorage read is enabled
    And speaker "John" has ActiveStorage attachment
    When I visit "/"
    And I click "講者" in menu
    Then I can see speaker "John" with ActiveStorage avatar

  @active_storage_read
  Scenario: Speaker avatar falls back to CarrierWave when no ActiveStorage attachment
    Given there are some speakers
      | name | slug | title             | order | description     | avatar   |
      | John | john | Sr. Game Engineer | 1     | Awesome speaker | TGDF.png |
    And ActiveStorage read is enabled
    And speaker "John" does not have ActiveStorage attachment
    When I visit "/"
    And I click "講者" in menu
    Then I can see speaker "John" with CarrierWave avatar

  # =============================================================================
  # Site - logo
  # =============================================================================

  @active_storage_read
  Scenario: Site logo uses default URL when no file uploaded
    Given there is a site without logo
    When I visit "/"
    Then I can see the default site logo

  @active_storage_read
  Scenario: Site logo served from ActiveStorage when read enabled
    Given ActiveStorage read is enabled
    And there is a site with ActiveStorage logo
    When I visit "/"
    Then I can see the ActiveStorage site logo

  # =============================================================================
  # News - thumbnail
  # =============================================================================

  @active_storage_read
  Scenario: News thumbnail served from CarrierWave when read disabled
    Given ActiveStorage read is disabled
    And there are some news
      | title      | content      | status    |
      | Test News  | Some content | published |
    When I visit "/news"
    Then I can see news with CarrierWave thumbnail

  @active_storage_read
  Scenario: News thumbnail served from ActiveStorage when read enabled
    Given ActiveStorage read is enabled
    And there are some news
      | title      | content      | status    |
      | Test News  | Some content | published |
    And news "Test News" has ActiveStorage attachment
    When I visit "/news"
    Then I can see news with ActiveStorage thumbnail

  # =============================================================================
  # Sponsor - logo
  # =============================================================================

  @active_storage_read
  Scenario: Sponsor logo served from CarrierWave when read disabled
    Given ActiveStorage read is disabled
    And there are some sponsor levels
      | name   | order |
      | Gold   | 1     |
    And there are some sponsors
      | name    | level | logo     | order |
      | Sponsor | Gold  | TGDF.png | 1     |
    When I visit "/"
    Then I can see sponsor with CarrierWave logo

  @active_storage_read
  Scenario: Sponsor logo served from ActiveStorage when read enabled
    Given ActiveStorage read is enabled
    And there are some sponsor levels
      | name   | order |
      | Gold   | 1     |
    And there are some sponsors
      | name    | level | logo     | order |
      | Sponsor | Gold  | TGDF.png | 1     |
    And sponsor "Sponsor" has ActiveStorage attachment
    When I visit "/"
    Then I can see sponsor with ActiveStorage logo

  # =============================================================================
  # Partner - logo
  # =============================================================================

  @active_storage_read
  Scenario: Partner logo served from CarrierWave when read disabled
    Given ActiveStorage read is disabled
    And there are some partner types
      | name  | order |
      | Media | 1     |
    And there are some partners
      | name    | type  | logo     | order |
      | Partner | Media | TGDF.png | 1     |
    When I visit "/"
    Then I can see partner with CarrierWave logo

  @active_storage_read
  Scenario: Partner logo served from ActiveStorage when read enabled
    Given ActiveStorage read is enabled
    And there are some partner types
      | name  | order |
      | Media | 1     |
    And there are some partners
      | name    | type  | logo     | order |
      | Partner | Media | TGDF.png | 1     |
    And partner "Partner" has ActiveStorage attachment
    When I visit "/"
    Then I can see partner with ActiveStorage logo

  # =============================================================================
  # Slider - image
  # =============================================================================

  @active_storage_read
  Scenario: Slider image served from CarrierWave when read disabled
    Given ActiveStorage read is disabled
    And there are some slide in "home"
      | image    |
      | TGDF.png |
    When I visit "/"
    Then I can see slider with CarrierWave image

  @active_storage_read
  Scenario: Slider image served from ActiveStorage when read enabled
    Given ActiveStorage read is enabled
    And there are some slide in "home"
      | image    |
      | TGDF.png |
    And the slider has ActiveStorage attachment
    When I visit "/"
    Then I can see slider with ActiveStorage image

  # =============================================================================
  # Game - thumbnail
  # =============================================================================

  @active_storage_read
  Scenario: Game thumbnail served from CarrierWave when read disabled
    Given ActiveStorage read is disabled
    And there are some indie space games
      | name      | thumbnail | description | team      |
      | Test Game | TGDF.png  | A fun game  | Test Team |
    When I visit "/indie_spaces"
    Then I can see game with CarrierWave thumbnail

  @active_storage_read
  Scenario: Game thumbnail served from ActiveStorage when read enabled
    Given ActiveStorage read is enabled
    And there are some indie space games
      | name      | thumbnail | description | team      |
      | Test Game | TGDF.png  | A fun game  | Test Team |
    And game "Test Game" has ActiveStorage attachment
    When I visit "/indie_spaces"
    Then I can see game with ActiveStorage thumbnail

  # =============================================================================
  # ActiveStorage Write functionality
  # =============================================================================

  @active_storage_write
  Scenario: Admin can upload file to ActiveStorage when write is enabled
    Given there are some speakers
      | name | slug | title             | order | description     | avatar   |
      | John | john | Sr. Game Engineer | 1     | Awesome speaker | TGDF.png |
    And an user logged as admin
    And ActiveStorage write is enabled
    When I visit "/admin"
    And I click admin sidebar "New" in "Speaker"
    And I fill the "speaker" form
      | field       | value             |
      | name        | Jane              |
      | slug        | jane              |
      | title       | Game Designer     |
      | order       | 2                 |
      | description | Awesome designer  |
    And I attach files to ActiveStorage in the "speaker" form
      | field  | value    |
      | avatar | TGDF.png |
    And I click "新增Speaker" button
    Then speaker "Jane" should have ActiveStorage attachment

  @active_storage_write
  Scenario: ActiveStorage uploaded files are served even when read flag is disabled
    Given there are some speakers
      | name | slug | title             | order | description     | avatar   |
      | John | john | Sr. Game Engineer | 1     | Awesome speaker | TGDF.png |
    And ActiveStorage read is disabled
    And ActiveStorage write is enabled
    And speaker "John" has ActiveStorage attachment
    When I visit "/"
    And I click "講者" in menu
    Then I can see speaker "John" with ActiveStorage avatar

  @active_storage_write
  Scenario: CarrierWave files still served when only write flag is enabled
    Given there are some speakers
      | name | slug | title             | order | description     | avatar   |
      | John | john | Sr. Game Engineer | 1     | Awesome speaker | TGDF.png |
    And ActiveStorage read is disabled
    And ActiveStorage write is enabled
    And speaker "John" does not have ActiveStorage attachment
    When I visit "/"
    And I click "講者" in menu
    Then I can see speaker "John" with CarrierWave avatar
