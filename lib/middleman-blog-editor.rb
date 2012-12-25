require "middleman-core"
require "middleman-blog"

Middleman::Extensions.register(:blog_editor) do
  require "middleman-blog-editor/extension"
  Middleman::BlogEditor
end