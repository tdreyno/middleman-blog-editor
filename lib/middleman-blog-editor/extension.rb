require "pry"
require "pry-debugger"
require "sinatra"
require "json"

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
      options.accounts    ||= []

      app.after_configuration do
        mm = self
        map(options.mount_at) do
          use ::Rack::Auth::Basic, "Restricted Area" do |username, password|
            options.accounts.any? { |a| a.auth?(username, password) }
          end
        	run ::Middleman::BlogEditor::App.new(mm, options)
        end
      end
    end
    alias :included :registered
  end

  class App < ::Sinatra::Base
    set :static, true
    set :root, File.dirname(__FILE__)

    def initialize(middleman, options)
      @middleman = middleman
      @options = options
      super()
    end

  	get '/' do
  		erb :index
  	end
    
    get '/api/articles' do
      content_type :json

      {
        :articles => @middleman.blog.articles.map { |a| 
          {
            :id => a.slug,
            :published => a.published?,
            :body => a.body,
            :tags => a.tags.join(", "),
            :date => a.date,
            :slug => a.slug,
            :title => a.title,
            :frontmatter => a.data
          }
        }
      }.to_json
    end
    
    get '/api/articles/:slug' do
      content_type :json

      a = @middleman.blog.articles.find { |b| b.slug === params[:slug] }

      return halt(404) unless a

      {
        :article => {
          :id => a.slug,
          :published => a.published?,
          :body => a.body,
          :tags => a.tags.join(", "),
          :date => a.date,
          :slug => a.slug,
          :title => a.title,
          :frontmatter => a.data
        }
      }.to_json
    end

  end
end
