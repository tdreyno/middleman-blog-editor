require "middleman-core"
require "middleman-blog"

Middleman::Extensions.register(:blog_editor) do
  if defined?(::Middleman::Extension)
    require "middleman-blog-editor/extension_3_1"
    ::Middleman::BlogEditorExtension
  else
    require "middleman-blog-editor/extension_3_0"
    ::Middleman::BlogEditor
  end
end