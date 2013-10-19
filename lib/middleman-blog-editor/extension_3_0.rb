# require "pry"
# require "pry-debugger"
require "middleman-blog-editor/editor_ui"
require "middleman-blog-editor/rest_api"

# Blog Editor extension
module Middleman::BlogEditor

  class Options
    KEYS = [
            :mount_at,
            :accounts,
            :admin_title,
            :use_minified_assets,
            :show_edit_links_in_preview
           ]
    
    KEYS.each do |name|
      attr_accessor name
    end
    
    def initialize(options={})
      options.each do |k,v|
        self.send(:"#{k}=", v)
      end
    end
  end

  # Setup extension
  class << self

    # Once registered
    def registered(app, options_hash={}, &block)
      options = Options.new(options_hash)
      yield options if block_given?

      options.admin_title ||= 'Blog Editor'
      options.mount_at    ||= '/editor'
      options.use_minified_assets = true if options.use_minified_assets.nil?
      options.show_edit_links_in_preview = true if options.show_edit_links_in_preview.nil?
      # options.accounts    ||= []

      # ::Middleman::Sitemap::Resource.send :include, BlogArticleMethods

      app.after_configuration do
        mm = self
        if !mm.build?
          map(options.mount_at) do
            # use ::Rack::Auth::Basic, "Restricted Area" do |username, password|
            #   options.accounts.any? { |a| a.auth?(username, password) }
            # end
            
            if options.use_minified_assets
              use Rack::Deflater
            end

            run ::Middleman::BlogEditor::EditorUI.new(mm, options)

            map('/api') do
              run ::Middleman::BlogEditor::RestAPI.new(mm, options)
            end
          end

          if options.show_edit_links_in_preview
            use InjectEditorLinks, :mm => mm, :prefix => options.mount_at
          end
        end
      end
    end
    alias :included :registered
  end

  class ::Middleman::BlogEditor::InjectEditorLinks
    def initialize(app, options={})
      @app = app
      @mm = options[:mm]
      @prefix = options[:prefix]
    end
    
    def call(env)
      status, headers, response = @app.call(env)

      url = env["PATH_INFO"]
      if @mm.blog.path_matcher.match(url.sub(/^\//, ''))
        html = ::Middleman::Util.extract_response_text(response)

        a = @mm.blog.articles.find do |b|
          b.url === url
        end

        if a
          editor_url = "#{@prefix}#/edit/#{a.data["blog_editor_id"]}"

          html.sub!("</body>", <<-eos)
            <style>
              .mm-blog-editor-button{-webkit-box-sizing:border-box;-moz-box-sizing:border-box;box-sizing:border-box;font-family:"Helvetica Neue","Helvetica",Helvetica,Arial,sans-serif;width:auto;background:#2ba6cb;border:1px solid #1e728c;-webkit-box-shadow:0 1px 0 rgba(255,255,255,0.5) inset;-moz-box-shadow:0 1px 0 rgba(255,255,255,0.5) inset;box-shadow:0 1px 0 rgba(255,255,255,0.5) inset;color:#fff;cursor:pointer;display:inline-block;font-size:14px;font-weight:bold;line-height:1;margin:0;outline:none;padding:10px 20px 11px;position:relative;text-align:center;text-decoration:none;-webkit-transition:background-color 0.15s ease-in-out;-moz-transition:background-color 0.15s ease-in-out;-o-transition:background-color 0.15s ease-in-out;transition:background-color 0.15s ease-in-out}.mm-blog-editor-button:hover{color:#fff;background-color:#2284a1}.mm-blog-editor-button:active{-webkit-box-shadow:0 1px 0 rgba(0,0,0,0.2) inset;-moz-box-shadow:0 1px 0 rgba(0,0,0,0.2) inset;box-shadow:0 1px 0 rgba(0,0,0,0.2) inset}.mm-blog-editor-button:focus{-webkit-box-shadow:0 0 4px #2ba6cb,0 1px 0 rgba(255,255,255,0.5) inset;-moz-box-shadow:0 0 4px #2ba6cb,0 1px 0 rgba(255,255,255,0.5) inset;box-shadow:0 0 4px #2ba6cb,0 1px 0 rgba(255,255,255,0.5) inset;color:#fff}
            </style>
            <a href="#{editor_url}" target="_blank" class="mm-blog-editor-button" style="position: absolute; top: 5px; right: 5px;">Edit Blog Post</a>
            </body>
          eos

          headers["Content-Length"] = ::Rack::Utils.bytesize(html).to_s
          response = [html]
        end
      end

      [status, headers, response]
    end
  end

  # module BlogArticleMethods
  #   def blog_editor_id
  #     if @blog_editor_id
  #       @@blog_editor_next_id ||= 1
  #       @blog_editor_id = @@blog_editor_next_id
  #       @@blog_editor_next_id += 1
  #     end

  #     @blog_editor_id
  #   end
  # end
end
