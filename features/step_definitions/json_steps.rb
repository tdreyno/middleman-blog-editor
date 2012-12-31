Then /^there should be (\d+) frontmatter models and (\d+) article models$/ do |arg1, arg2|
  data = JSON.parse(@browser.last_response.body)
  data["frontmatters"].length.should === arg1.to_i
  data["articles"].length.should === arg2.to_i
end

Then /^the article title should be "(.*?)"$/ do |arg1|
  data = JSON.parse(@browser.last_response.body)
  article_id = data["article"]["id"]
  a = data["frontmatters"].find { |d| d["id"] === "#{article_id}-title"}
  a["key"].should === "title"
  a["value"].should === arg1
end
