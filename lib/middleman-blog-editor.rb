require "middleman-core"
require "middleman-blog"

Middleman::Extensions.register(:blog_editor) do
  require "middleman-blog-editor/extension_3_1"
  ::Middleman::BlogEditorExtension
end