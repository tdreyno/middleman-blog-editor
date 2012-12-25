require "pry"
require "pry-debugger"
require "sinatra"

# Blog Editor extension
module Middleman::BlogEditor

  class Options
    KEYS = [
            :mount_at,
            :accounts
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

      options.mount_at ||= '/editor'
      options.accounts ||= []

      app.after_configuration do
        mm = self
        map(options.mount_at) do
          use ::Rack::Auth::Basic, "Restricted Area" do |username, password|
            options.accounts.any? { |a| a.auth?(username, password) }
          end
        	run ::Middleman::BlogEditor::App.new(mm)
        end
      end
    end
    alias :included :registered
  end

  class App < ::Sinatra::Base
    def initialize(middleman)
      @middleman = middleman
      super
    end

  	get '/' do
  		@middleman.inspect
  	end
  end
end
