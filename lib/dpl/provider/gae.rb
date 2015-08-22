require 'open-uri'
require 'rubygems/package'
require 'zlib'

module DPL
  class Provider
    class GAE < Provider
      experimental 'Google App Engine'

      BASE="https://dl.google.com/dl/cloudsdk/channels/rapid/"
      NAME="google-cloud-sdk"
      EXT=".tar.gz"
      GCLOUD=File.join(Dir.home, NAME, "bin", "gcloud")

      def self.install_sdk
        # If the gcloud executable exists, assume everything is fine.
        if File.exists? GCLOUD
          return
        end

        $stderr.puts "Downloading Google Cloud SDK"

        Gem::Package::TarReader.new(Zlib::GzipReader.open(open(BASE + NAME + EXT, "rb"))).each do |entry|
          target = File.join(Dir.home, entry.full_name)
          if entry.directory?
            FileUtils.mkdir_p target, :mode => entry.header.mode
          elsif entry.file?
            File.open target, "wb" do |f|
              f.print entry.read
            end
            FileUtils.chmod entry.header.mode, target
          end
        end

        # Bootstrap the Google Cloud SDK.
        unless context.shell("CLOUDSDK_CORE_DISABLE_PROMPTS=1 #{Dir.home}/#{NAME}/bin/bootstrapping/install.py --usage-reporting=false --command-completion=false --path-update=false --additional-components=preview")
          raise Error, 'Could not install Google Cloud SDK!'
        end
      end

      install_sdk

      def needs_key?
        false
      end

      def check_auth
        command = GCLOUD + " -q --verbosity debug auth activate-service-account --key-file #{keyfile}"
        unless context.shell(command)
          raise Error, 'Failed to authenticate!'
        end
      end

      def keyfile
        options[:keyfile] || context.env['GOOGLECLOUDKEYFILE'] || 'service-account.json'
      end

      def project
        options[:project] || context.env['GOOGLECLOUDPROJECT'] || context.env['CLOUDSDK_CORE_PROJECT'] || File.dirname(context.env['TRAVIS_REPO_SLUG'] || '')
      end

      def version
        options[:version] || ""
      end

      def config
        options[:config] || 'app.yaml'
      end

      def default
        options[:default]
      end

      def verbosity
        options[:verbosity] || "warning"
      end

      def push_app
        command = GCLOUD
        command << " --quiet"
        command << " --verbosity \"#{verbosity}\""
        command << " --project \"#{project}\""
        command << " preview app deploy \"#{config}\""
        command << " --version \"#{version}\""
        command << (default ? " --set-default" : "")
        context.shell(command)
      end
    end
  end
end
