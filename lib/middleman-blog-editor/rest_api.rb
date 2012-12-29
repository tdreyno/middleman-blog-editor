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
      
      def article_by_slug(slug)
        a = @middleman.blog.articles.find { |b| b.slug === slug }

        return halt(404) unless a

        a
      end

      def write_article(a, data, body)
        contents = %Q{#{data.to_yaml}---

#{body}}

        File.open(a.source_file, 'w') {|f| f.write(contents) }

        @middleman.sitemap.rebuild_resource_list!
      end

      def write_body(a, json)
        data, body = @middleman.frontmatter_manager.data(a.source_file)
        data = {}.merge(data)
        body = json["body"]

        write_article(a, data, body)
      end

      def write_frontmatter(a, json)
        data, body = @middleman.frontmatter_manager.data(a.source_file)
        data = {}.merge(data)

        key = json["key"]

        if json["value"] === "true" || json["value"] === "false"
          data[key] = json["value_boolean"]
        else
          data[key] = json["value"]
        end

        if key === "published" && data[key] === true
          data.delete(key)
        end

        write_article(a, data, body)
      end

      get '/articles/:slug' do
        content_type :json

        a = article_by_slug(params[:slug])
        out = article_to_h(a)

        {
          :frontmatters => out[1],
          :article => out[0]
        }.to_json
      end

      put '/articles/:slug' do
        content_type :json

        json = JSON.parse(request.body.read)

        a = article_by_slug(params[:slug])

        write_body(a, json["article"])
        
        {}.to_json
      end

      put '/frontmatters/:slug' do
        content_type :json

        json = JSON.parse(request.body.read)

        a = article_by_slug(json["frontmatter"]["article_id"])

        write_frontmatter(a, json["frontmatter"])

        {}.to_json
      end

    end
  end
end