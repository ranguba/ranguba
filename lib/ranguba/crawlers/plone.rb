require "json"
require "net/http"
require "uri"

module Ranguba
  module Crawlers
    class Plone
      def initialize(url, user: nil, password: nil)
        @url = url
        @user = user
        @password = password
        @processed_urls = {}
      end

      def crawl(&block)
        crawl_recursive(@url, &block)
      end

      private
      def crawl_recursive(url, &block)
        return if @processed_urls.include?(url)
        response = get(url)
        content = Content.new
        content.url = response["@id"]
        content.title = response["title"]
        if response["file"]
          content.body = download(response["file"]["download"])
          content.type = response.dig("file", "content-type")
        else
          content.body = response.dig("text", "data")
          content.type = response.dig("text", "content-type")
          content.encoding = response.dig("text", "encoding")
        end
        content.basename = content.url.split(/\//).last
        modified = response["modified"]
        content.modified_time = Time.parse(modified) if modified
        @processed_urls[content.url] = true
        yield(content)
        (response["items"] || []).each do |item|
          crawl_recursive(item["@id"], &block)
        end
      end

      def get(url)
        uri = URI(url)
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new(uri)
          request.basic_auth(@user, @password) if @user and @password
          request["Accept"] = "application/json"
          http.request(request)
        end
        JSON.parse(response.body)
      end

      def download(url)
        uri = URI(url)
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new(uri)
          request.basic_auth(@user, @password) if @user and @password
          http.request(request)
        end
        response.body
      end

      class Content < Struct.new(:url,
                                 :title,
                                 :body,
                                 :type,
                                 :encoding,
                                 :basename,
                                 :modified_time)
      end
    end
  end
end
