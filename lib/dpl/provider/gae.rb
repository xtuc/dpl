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
        puts "install_sdk (early) Is it there? " + (File.exist?(GCLOUD) ? "Yep :)" : "Nope :(")
        # If the gcloud executable exists, assume everything is fine.
        if File.exist?(GCLOUD)
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

        puts "install_sdk (before actually installing) Is it there? " + (File.exist?(GCLOUD) ? "Yep :)" : "Nope :(")

        # Bootstrap the Google Cloud SDK.
        context.shell("CLOUDSDK_CORE_DISABLE_PROMPTS=1 #{Dir.home}/#{NAME}/bin/bootstrapping/install.py --usage-reporting=false --command-completion=false --path-update=false --additional-components=preview")

        puts "install_sdk (late) Is it there? " + (File.exist?(GCLOUD) ? "Yep :)" : "Nope :(")
      end

      install_sdk

      def needs_key?
        false
      end

      def cleanup
        puts "cleanup Is it there? " + (File.exist?(GCLOUD) ? "Yep :)" : "Nope :(")
      end

      def check_auth
        puts "check_auth (late) Is it there? " + (File.exist?(GCLOUD) ? "Yep :)" : "Nope :(")
        context.shell(GCLOUD + " -q --verbosity debug auth activate-service-account --key-file #{keyfile}")
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
        puts "push_app (late) Is it there? " + (File.exist?(GCLOUD) ? "Yep :)" : "Nope :(")
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
