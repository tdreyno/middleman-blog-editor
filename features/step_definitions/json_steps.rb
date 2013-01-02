Then /^there should be (\d+) article models$/ do |model_count|
  data = JSON.parse(@browser.last_response.body)
  data["articles"].length.should === model_count.to_i
end

Then /^the article title should be "(.*?)"$/ do |article_title|
  data = JSON.parse(@browser.last_response.body)
  fm = JSON.parse(data["article"]["frontmatter"])
  fm["title"].should === article_title
end
