require "middleman-core"

Middleman::Extensions.register(:blog_editor) do
  require "middleman-blog-editor/extension"
  Middleman::BlogEditor
end