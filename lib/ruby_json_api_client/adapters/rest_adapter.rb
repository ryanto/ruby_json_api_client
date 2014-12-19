require 'faraday'
require 'faraday_middleware'
require "addressable/uri"
require 'json'
require 'active_support'

module RubyJsonApiClient
  class RestAdapter
    attr_accessor :secure
    attr_accessor :hostname
    attr_accessor :namespace
    attr_accessor :port
    attr_accessor :url_root
    attr_accessor :http_client
    attr_accessor :required_query_params

    def initialize(options = {})
      if options[:http_client].nil?
        options[:http_client] = :net_http
      end

      options.each do |(field, value)|
        send("#{field}=", value)
      end
    end

    def single_path(klass, params = {})
      name = klass.name
      plural = ActiveSupport::Inflector.pluralize(name)
      path = plural.underscore
      id = params[:id]
      "#{@namespace}/#{path}/#{id}"
    end

    def collection_path(klass, params)
      name = klass.name
      plural = ActiveSupport::Inflector.pluralize(name)
      "#{@namespace}/#{plural.underscore}"
    end

    def accept_header
      'application/json'
    end

    def user_agent
      'RubyJsonApiClient'
    end

    def headers
      {
        accept: accept_header,
        user_user: user_agent
      }
    end

    def find(klass, id)
      raise "Cannot find nil id" if id.nil?

      path = single_path(klass, id: id)
      status, _, body = http_request(:get, path, {})

      if status >= 200 && status <= 299
        body
      elsif status == 404
        nil
      else
        raise "Could not find #{klass.name} with id #{id}"
      end
    end

    def find_many(klass, params)
      path = collection_path(klass, params)
      status, _, body = http_request(:get, path, params)

      if status >= 200 && status <= 299
        body
      else
        raise "Could not query #{klass.name}"
      end
    end

    def create(model, data)
      url = collection_path(model.class, {})
      status, _, body = http_request(:post, url, data)

      if status >= 200 && status <= 299
        body
      else
        raise "Could not post to #{url}"
      end
    end

    def update(model, data)
      url = single_path(model.class, { id: model.id })
      status, _, body = http_request(:put, url, data)

      if status >= 200 && status <= 299
        body
      else
        raise "Could not put to #{url}"
      end
    end

    def delete(model)
      url = single_path(model.class, { id: model.id })
      status, _, body = http_request(:delete, url, {})

      if status >= 200 && status <= 299
        body
      else
        raise "Could not delete to #{url}"
      end
    end

    def get(url)
      status, _, body = http_request(:get, url, {})

      if status >= 200 && status <= 299
        body
      else
        raise "Could not query #{url}"
      end
    end

    protected

    def http_request(method, url, params)
      uri = Addressable::URI.parse(url)

      proto = uri.scheme || (@secure ? "https" : "http")
      hostname = uri.host || @hostname
      port = uri.port || @port || (@secure ? 443 : 80)
      path = uri.path

      query_params = (required_query_params || {})
        .merge(uri.query_values || {})
        .merge(params)

      conn = Faraday.new("#{proto}://#{hostname}:#{port}", {
        headers: headers
      }) do |f|
        f.request :json
        f.adapter @http_client
      end

      response = conn.send(method, path, query_params)
      [response.status, response.headers, response.body]
    end
  end
end
