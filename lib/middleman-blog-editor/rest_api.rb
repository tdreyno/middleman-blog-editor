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

        @next_blog_editor_id = 0
        scan_for_next_blog_editor_id
        ensure_every_article_has_an_id

        super()
      end

      def scan_for_next_blog_editor_id
        @middleman.blog.articles.each { |a|
          if a.data["blog_editor_id"]
            if a.data["blog_editor_id"] > @next_blog_editor_id
              @next_blog_editor_id = a.data["blog_editor_id"]
            end
          end
        }
      end

      def ensure_every_article_has_an_id
        @middleman.blog.articles.each { |a|
          if !a.data["blog_editor_id"]
            @next_blog_editor_id += 1

            write_frontmatter(a, {
              "key" => "blog_editor_id",
              "value" => @next_blog_editor_id
            })
          end
        }
      end

      def article_to_h(a)
        data, raw = @middleman.frontmatter_manager.data(a.source_file)

        {
          :id => a.data["blog_editor_id"],
          # :body => a.body,
          :raw => raw,
          :date => a.date,
          :slug => a.slug,
          :source => a.source_file.sub(@middleman.root, ''),
          :frontmatter => a.data.to_json,
          :engine => File.extname(a.source_file).sub(/^\./, '')
        }
      end

      get '/articles' do
        content_type :json

        {
          :articles => @middleman.blog.articles.map { |a| 
            article_to_h(a)
          }
        }.to_json
      end
      
      def article_by_id(id)
        @lock.synchronize do
          a = @middleman.blog.articles.find do |b|
            b.data["blog_editor_id"] === id.to_i
          end

          return halt(404) unless a

          a
        end
      end

      def delete_article(a)
        @lock.synchronize do
          FileUtils.rm(a.source_file)

          @middleman.files.reload_path(@middleman.source, true)
          @middleman.sitemap.rebuild_resource_list!
          @middleman.sitemap.ensure_resource_list_updated!
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

      def write_frontmatter(a, json)
        @lock.synchronize do
          data, body = @middleman.frontmatter_manager.data(a.source_file)
          data = {}.merge(data)

          key = json["key"]

          if json["value"] === "true"
            data[key] = true
          elsif json["value"] === "false"
            data[key] = false
          else
            data[key] = json["value"]
          end

          if key === "published" && data[key] === true
            data.delete(key)
          end

          write_article(a.source_file, data, body)
        end
      end

      get '/articles/:id' do
        content_type :json

        a = article_by_id(params[:id])

        {
          :article => article_to_h(a)
        }.to_json
      end

      put '/articles/:id' do
        content_type :json

        json = JSON.parse(request.body.read)

        a = article_by_id(params[:id])

        new_source_file = get_source_file(json)
        
        if a.source_file != new_source_file
          FileUtils.rm(a.source_file)
        end

        data = JSON.parse(json["article"]["frontmatter"])
        write_article(new_source_file, data, json["article"]["raw"])
        
        a = article_by_id(params[:id])
        
        {
          :article => article_to_h(a)
        }.to_json
      end

      def get_source_file(json)
        date = Date.parse(json["article"]["date"])
        source_path = File.join(@middleman.source_dir, @middleman.blog.options.sources)
        
        source_file = source_path.
          sub(":year",  date.strftime('%Y')).
          sub(":month", date.strftime('%m')).
          sub(":day",   date.strftime('%d')).
          sub(":title", json["article"]["slug"])

        source_file = "#{source_file}.#{json["article"]["engine"]}"
        source_file
      end

      post '/articles' do
        content_type :json

        json = JSON.parse(request.body.read)
        source_file = get_source_file(json)

        body = json["article"]["raw"]
        data = JSON.parse(json["article"]["frontmatter"])
        @next_blog_editor_id += 1

        data["blog_editor_id"] = @next_blog_editor_id
        write_article(source_file, data, body)
        
        a = article_by_id(@next_blog_editor_id)

        {
          :article => article_to_h(a)
        }.to_json
      end

      delete '/articles/:id' do
        content_type :json

        a = article_by_id(params[:id])

        delete_article(a)

        {
        }.to_json
      end

    end
  end
end