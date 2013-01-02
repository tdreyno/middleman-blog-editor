activate :blog do |blog|
  blog.sources = ":year/:month/:day/:title.html"
end

activate :blog_editor do |editor|
  # Where to place the editor UI.
  editor.mount_at = "/editor"
  editor.use_minified_assets = false
end