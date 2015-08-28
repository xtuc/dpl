module DPL
  class Provider
    class CloudFoundry < Provider

      def initial_go_tools_install
        context.shell 'curl -sSL -o- http://go-cli.s3-website-us-east-1.amazonaws.com/releases/latest/cf-cli_amd64.deb | tar xf - data.tar.xz && tar xf data.tar.xz --strip-components 3 ./usr/bin/cf; rm -f data.tar.xz'
      end

      def check_auth
        initial_go_tools_install
        context.shell "./cf api #{option(:api)} #{'--skip-ssl-validation' if options[:skip_ssl_validation]}"
        context.shell "./cf login --u #{option(:username)} --p #{option(:password)} --o #{option(:organization)} --s #{option(:space)}"
      end

      def check_app
        if options[:manifest]
          error 'Application must have a manifest.yml for unattended deployment' unless File.exists? options[:manifest]
        end
      end

      def needs_key?
        false
      end

      def push_app
        context.shell "./cf push#{manifest}"
        context.shell "./cf logout"
      end

      def cleanup
      end

      def uncleanup
      end

      def manifest
        options[:manifest].nil? ? "" : " -f #{options[:manifest]}"
      end
    end
  end
end
