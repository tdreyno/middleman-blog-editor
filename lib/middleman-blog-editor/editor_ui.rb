require "sinatra"

module Middleman
  module BlogEditor
    class EditorUI < ::Sinatra::Base
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
    end
  end
end