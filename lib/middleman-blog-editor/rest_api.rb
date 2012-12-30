require "fileutils"
require "sinatra"
require "json"
# require 'monitor'

module Middleman
  module BlogEditor
    class RestAPI < ::Sinatra::Base
      # set :static, true
      # set :root, File.dirname(__FILE__)
      set :lock, true

      def initialize(middleman, options)
        @middleman = middleman
        @options = options
        @lock = Monitor.new
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

        data, raw = @middleman.frontmatter_manager.data(a.source_file)

        [{
          :id => a.slug,
          :body => a.body,
          :raw => raw,
          :date => a.date,
          :slug => a.slug,
          :source => a.source_file.sub(@middleman.root, ''),
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
        @lock.synchronize do
          a = @middleman.blog.articles.find { |b| b.slug === slug }

          return halt(404) unless a

          a
        end
      end

      def write_article(source_file, data, body)
        @lock.synchronize do
          contents = ""
          if !data.nil? && data.keys.length > 0
            contents << %Q{#{data.to_yaml}---\n\n}
          end

          contents << body

          FileUtils.mkdir_p(File.dirname(source_file))
          File.open(source_file, 'w') {|f| f.write(contents) }

          @middleman.files.reload_path(@middleman.source, true)
          @middleman.sitemap.rebuild_resource_list!
          @middleman.sitemap.ensure_resource_list_updated!
        end
      end

      def write_body(a, body)
        # @lock.synchronize do
          data = {}.merge(@middleman.frontmatter_manager.data(a.source_file)[0])
          write_article(a.source_file, data, body)
        # end
      end

      def write_frontmatter(a, json)
        # @lock.synchronize do
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

          write_article(a.source_file, data, body)
        # end
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

        body = json["article"]["engine"] === "erb" ? json["article"]["body"] : json["article"]["raw"]

        write_body(a, body)
        
        {}.to_json
      end

      post '/articles' do
        content_type :json

        json = JSON.parse(request.body.read)
        date = Date.parse(json["article"]["date"])
        source_path = File.join(@middleman.source_dir, @middleman.blog.options.sources)
        
        source_file = source_path.
          sub(":year",  date.strftime('%Y')).
          sub(":month", date.strftime('%m')).
          sub(":day",   date.strftime('%d')).
          sub(":title", json["article"]["slug"])

        body = json["article"]["engine"] === "erb" ? json["article"]["body"] : json["article"]["raw"]
        write_article("#{source_file}.#{json["article"]["engine"]}", nil, body)
        
        {}.to_json
      end

      def update_frontmatter(fm)
        a = article_by_slug(fm["article_id"])

        write_frontmatter(a, fm)
      end

      put '/frontmatters/:slug' do
        content_type :json

        json = JSON.parse(request.body.read)
        update_frontmatter(json["frontmatter"])

        {}.to_json
      end

      post '/frontmatters' do
        content_type :json

        json = JSON.parse(request.body.read)
        update_frontmatter(json["frontmatter"])
        
        {}.to_json
      end

    end
  end
end