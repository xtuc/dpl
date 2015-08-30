require 'json'
require 'uri'

module DPL
  class Provider
    requires 'faraday'

    DEFAULT_API_HOST     = "https://api.travis-ci.org"

    class TravisCi < Provider
      def check_auth
      end

      def needs_key?
        false
      end

      def push_app
        conn = Faraday.new(url: api_host) do  |faraday|
          faraday.request  :url_encoded
          faraday.adapter  Faraday.default_adapter
        end

        response = conn.post do |req|
          req.url api_endpoint
          req.headers['Content-Type'] = 'application/json'
          req.headers['Accept'] = 'application/json'
          req.headers['Travis-API-Version'] = '3'
          req.headers['Authorization'] = "token #{api_build_token}"
          req.body = {request: JSON.parse(options[:request])}.to_json
        end

        message = response.success? ? "Successfully triggered a build" : "Build request failed"
        log "#{message}\nstatus: #{response.status}\nbody: #{response.body}"
      end

      def api_build_token
        options[:token] || ENV['TRAVIS_BUILD_TOKEN']
      end

      def api_host
        options[:api_host] || DEFAULT_API_HOST
      end

      def api_endpoint
        '/repo/%s/requests' % URI.encode_www_form_component(option(:repo))
      end

    end
  end
end
