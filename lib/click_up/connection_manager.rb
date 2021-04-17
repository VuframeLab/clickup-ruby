# frozen_string_literal: true

module ClickUp

  # FIXME: requests are limited to 100 requests per minute
  class ConnectionManager
    attr_reader :path, :data

    def initialize(path, data)
      @path = path
      @data = data
    end

    def get
      request_block do
        https_client.request_get(resource_url, default_headers)
      end
    end

    def post
      request_block do
        form_data = data.to_json if data.is_a?(Hash) && data.size > 0
        https_client.request_post(resource_url.path, form_data, default_headers)
      end
    end

    def put
      request_block do
        form_data = data.to_json if data.is_a?(Hash) && data.size > 0
        https_client.request_put(resource_url.path, form_data, default_headers)
      end
    end

    def delete
      request_block do
        net_http_response = https_client.delete(resource_url, default_headers)
        format_response(net_http_response.body)
      end
    end

    private

    def request_block
      net_http_response = yield
      res = format_response(net_http_response.body)
      unless net_http_response.code == 200 || net_http_response.code == '200'
        puts "Got error with code '#{net_http_response.code}': #{res['err']}"
        if res.key?('err') && res['ECODE'] == 'APP_002'
          # This error will be thrown, when we hit the request limit per minute from clickup (100).
          # We will wait 30 seconds and try it again.
          puts 'Waiting for 30 seconds to continue'
          sleep(30)
          net_http_response = yield
          return format_response(net_http_response.body)
        elsif res.key?('err') && res['ECODE'] == 'OAUTH_027'
          puts 'FIXME: This request is currently not working.' if ClickUp.debug
        end
      end
      res
    end

    def resource_url
      uri = URI("#{api_base}#{namespace}#{path}")
      uri.query = URI.encode_www_form(data) if data.size > 0
      uri
    end

    def namespace
      "/api/v2"
    end

    def api_base
      "https://api.clickup.com"
    end

    def default_headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => ClickUp.api_token
      }
    end

    def format_response(net_http_response)
      JSON.parse(net_http_response)
    end

    def https_client
      https = Net::HTTP.new(resource_url.host, resource_url.port)
      https.set_debug_output($stdout) if ClickUp.debug
      https.use_ssl = true
      https
    end
  end
end