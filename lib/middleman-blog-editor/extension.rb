require "pry"
require "pry-debugger"
require "middleman-blog-editor/editor_ui"
require "middleman-blog-editor/rest_api"

# Blog Editor extension
module Middleman::BlogEditor

  class Options
    KEYS = [
            :mount_at,
            :accounts,
            :admin_title
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

      options.admin_title ||= 'Middleman Blog Editor'
      options.mount_at    ||= '/editor'
      # options.accounts    ||= []

      # ::Middleman::Sitemap::Resource.send :include, BlogArticleMethods

      app.after_configuration do
        mm = self
        if !mm.build?
          map(options.mount_at) do
            # use ::Rack::Auth::Basic, "Restricted Area" do |username, password|
            #   options.accounts.any? { |a| a.auth?(username, password) }
            # end
            
            run ::Middleman::BlogEditor::EditorUI.new(mm, options)

            map('/api') do
              run ::Middleman::BlogEditor::RestAPI.new(mm, options)
            end
          end
        end
      end
    end
    alias :included :registered
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
