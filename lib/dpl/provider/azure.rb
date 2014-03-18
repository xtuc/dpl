require 'dpl/provider'

module DPL
  class Provider
    class Azure < Provider
      ENDPOINT = "https://management.core.windows.net"
      requires 'azure'

      def check_auth
        Azure.configure do |config|
          config.management_certificate = option(:management_certificate)
          config.subscription_id        = option(:subscription_id)
          config.management_endpoint    = options[:management_endpoint] || ENDPOINT
        end
      end
    end
  end
end
