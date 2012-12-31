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
    And there should be 6 frontmatter models and 2 article models

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
    And there should be 6 frontmatter models and 2 article models

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
    And there should be 7 frontmatter models and 3 article models

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
      ---

      2013!
      """
    And the Server is running
    When I go to "/editor/api/articles/happy-new-year"
    Then I should not see "Not Found"
    And the article title should be "Happy New Year"
    Then I should see "2013!"
