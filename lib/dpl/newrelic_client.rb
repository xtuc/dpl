require 'faraday'

module DPL
  class NewRelicClient
    NEWRELIC_API_HOST='https://api.newrelic.com'

    def self.notify(opts)
      if (!opts[:app_name] && !opts[:application_id]) || (opts[:app_name] && opts[:application_id])
        log "Exactly one of app_name or application_id is required.\nNot notifying New Relic"
        return
      end

      payload = []
      opts.each_pair do |k,v|
        payload << "deployment[#{k.to_s}]=#{v}"
      end

      conn = Faraday.new(:url => NEWRELIC_API_HOST) do |faraday|
        faraday.adapter Faraday.default_adapter
      end

      response = conn.post do |req|
        req.url '/deployments.xml'

        req.headers['x-api-key']     = opts[:api_key]     if opts[:api_key]
        req.headers['x-license-key'] = opts[:license_key] if opts[:license_key]

        req.body = payload.join('&')
      end

      if response.success?
        log "Notified New Relic"
      else
        log "Notification to New Relic failed.\nStatus: #{response.status}"
      end
    end
  end
end
