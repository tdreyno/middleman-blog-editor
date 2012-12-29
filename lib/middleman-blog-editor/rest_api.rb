require "sinatra"
require "json"

module Middleman
  module BlogEditor
    class RestAPI < ::Sinatra::Base
      # set :static, true
      # set :root, File.dirname(__FILE__)

      def initialize(middleman, options)
        @middleman = middleman
        @options = options
        super()
      end

      def article_to_h(a)
        frontmatter_data = []
        a.data.each do |k,v|
          frontmatter_data << {
            :id => "#{a.slug}-#{k}",
            :key => k,
            :value => v,
            :article_id => a.slug
          }
        end

        [{
          :id => a.slug,
          :body => a.body,
          :date => a.date,
          :slug => a.slug,
          :frontmatters => frontmatter_data.map { |d| d[:id] },
          :engine => File.extname(a.source_file).sub(/^\./, '')
        }, frontmatter_data]
      end

      get '/articles' do
        content_type :json
        articles = []
        fmdata = []

        @middleman.blog.articles.each { |a| 
          out = article_to_h(a)
          articles << out[0]
          fmdata << out[1]
        }

        {
          :frontmatters => fmdata.flatten,
          :articles => articles
        }.to_json
      end
      
      get '/articles/:slug' do
        content_type :json

        a = @middleman.blog.articles.find { |b| b.slug === params[:slug] }

        return halt(404) unless a

        out = article_to_h(a)
        {
          :frontmatters => out[1],
          :article => out[0]
        }.to_json
      end

    end
  end
end