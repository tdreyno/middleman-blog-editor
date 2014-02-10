Feature: Rest API

  Scenario: Default Config
    Given a fixture app "blog-app"
    And a file named "config.rb" with:
      """
      activate :blog do |blog|
        blog.sources = ":year/:month/:day/:title.html"
      end

      activate :blog_editor
      """
    And the Server is running
    When I go to "/editor/api/articles"
    Then I should not see "Not Found"
    And there should be 3 article models

  Scenario: Alt Root
    Given a fixture app "blog-app"
    And a file named "config.rb" with:
      """
      activate :blog do |blog|
        blog.sources = ":year/:month/:day/:title.html"
      end

      activate :blog_editor do |editor|
        editor.mount_at = "/my_editor"
      end
      """
    And the Server is running
    When I go to "/editor/api/articles"
    Then I should see "Not Found"
    When I go to "/my_editor/api/articles"
    Then I should not see "Not Found"
    And there should be 3 article models

  Scenario: With extra articles
    Given a fixture app "blog-app"
    And a file named "config.rb" with:
      """
      activate :blog do |blog|
        blog.sources = ":year/:month/:day/:title.html"
      end

      activate :blog_editor
      """
    And a file named "source/2012/12/31/happy-new-year.html.erb" with:
      """
      ---
      title: "Happy New Year"
      ---

      2013!
      """
    And the Server is running
    When I go to "/editor/api/articles"
    Then I should not see "Not Found"
    And there should be 4 article models

  Scenario: Get Single Article
    Given a fixture app "blog-app"
    And a file named "config.rb" with:
      """
      activate :blog do |blog|
        blog.sources = ":year/:month/:day/:title.html"
      end

      activate :blog_editor
      """
    And a file named "source/2012/12/31/happy-new-year.html.erb" with:
      """
      ---
      title: "Happy New Year"
      blog_editor_id: 201
      ---

      2013!
      """
    And the Server is running
    When I go to "/editor/api/articles/201"
    Then I should not see "Not Found"
    And the article title should be "Happy New Year"
    Then I should see "2013!"

  Scenario: Every Article Should Get a Unique ID
    Given a fixture app "blog-app"
    And the Server is running
    When I go to "/editor/api/articles"
    Then every article should have a unique id

  Scenario: Updating Body
    Given a fixture app "blog-app"
    And the Server is running
    When I prepare to edit article at "/editor/api/articles/100"
    And I update the article body with:
      """
      Another Holiday
      """
    When I save the article to "/editor/api/articles/100"
    And I go to "/editor/api/articles/100"
    Then I should see "Another Holiday"

  Scenario: Updating Frontmatter Title
    Given a fixture app "blog-app"
    And the Server is running
    When I prepare to edit article at "/editor/api/articles/100"
    And I update the article frontmatter with:
      | key   | value     |
      | title | New Title |
    When I save the article to "/editor/api/articles/100"
    And I go to "/editor/api/articles/100"
    And the article title should be "New Title"

  Scenario: Updating Date
    Given a fixture app "blog-app"
    And the Server is running
    When I prepare to edit article at "/editor/api/articles/100"
    And I update the article date to "2012/12/26"
    When I save the article to "/editor/api/articles/100"
    Then a file named "source/2012/12/25/merry-christmas.html.md" should not exist
    And a file named "source/2012/12/26/merry-christmas.html.md" should exist
    When I go to "/editor/api/articles/100"
    Then the article date should be "2012/12/26"
    Then the article source should be "/source/2012/12/26/merry-christmas.html.md"

  Scenario: Updating Slug
    Given a fixture app "blog-app"
    And the Server is running
    When I prepare to edit article at "/editor/api/articles/100"
    And I update the article slug to "merrier-christmas"
    When I save the article to "/editor/api/articles/100"
    Then a file named "source/2012/12/25/merry-christmas.html.md" should not exist
    And a file named "source/2012/12/25/merrier-christmas.html.md" should exist
    When I go to "/editor/api/articles/100"
    Then the article slug should be "merrier-christmas"
    Then the article source should be "/source/2012/12/25/merrier-christmas.html.md"