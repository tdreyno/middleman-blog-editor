Then /^there should be (\d+) article models$/ do |model_count|
  data = JSON.parse(@browser.last_response.body)
  data["articles"].length.should === model_count.to_i
end

Then /^the article title should be "(.*?)"$/ do |article_title|
  data = JSON.parse(@browser.last_response.body)
  fm = JSON.parse(data["article"]["frontmatter"])
  fm["title"].should === article_title
end

Then /^every article should have a unique id$/ do
  in_current_dir do
    ids = Dir["source/20*/**/*.html.*"].map do |f|
      data = File.read(f)
      data.should_not be_nil
      data.match(/blog_editor_id: (\d+)/)[1].to_i
    end

    ids.should == ids.uniq

    # IDs start at 100, the highest existing ID found
    ids.sort.should == [100, 101, 102]
  end
end

Then /^the article date should be "(.*?)"$/ do |d|
  data = JSON.parse(@browser.last_response.body)
  Date.parse(data["article"]["date"]).should == Date.parse(d)
end

Then /^the article slug should be "(.*?)"$/ do |slug|
  data = JSON.parse(@browser.last_response.body)
  data["article"]["slug"].should == slug
end

Then /^the article source should be "(.*?)"$/ do |src|
  data = JSON.parse(@browser.last_response.body)
  data["article"]["source"].should == src
end

When /^I prepare to edit article at "(.*?)"$/ do |url|
  resp = @browser.get(URI.escape(url))
  data = JSON.parse(resp.body)
  data["article"]["frontmatter"] = JSON.parse(data["article"]["frontmatter"])
  @prepared_data = data
end

When /^I update the article frontmatter with:$/ do |table|
  table.rows.each do |r|
    @prepared_data["article"]["frontmatter"][r[0]] = r[1]
  end
end

When /^I update the article body with:$/ do |string|
  @prepared_data["article"]["raw"] = string
end

When /^I update the article slug to "(.*?)"$/ do |slug|
  @prepared_data["article"]["slug"] = slug
end

When /^I update the article date to "(.*?)"$/ do |d|
  @prepared_data["article"]["date"] = Date.parse(d)
end

When /^I save the article to "(.*?)"$/ do |url|
  data = @prepared_data.dup
  data["article"]["frontmatter"] = data["article"]["frontmatter"].to_json
  @browser.put(URI.escape(url), data.to_json, { "CONTENT_TYPE" => "application/json" })
end

