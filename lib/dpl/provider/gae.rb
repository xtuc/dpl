require 'open3'

module DPL
  class Provider
    class GAE < Provider
      experimental 'Google App Engine'

      BASE="https://dl.google.com/dl/cloudsdk/channels/rapid/"
      NAME="google-cloud-sdk"
      EXT=".tar.gz"
      GCLOUD=File.join(Dir.home, NAME, "bin", "gcloud")


      def self.run_command_and_wait_for_file(cmd, f, &block)
        stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
        while !File.exists?(f) do
          $stdout.write '.'
          sleep 1
        end
        $stdout.puts ''

        errors = stderr.read
        output = stdout.read
        status = wait_thr.value

        if !status.success?
          raise ["FAILED: #{cmd}", errors, output].join("\n")
        end
      end

      def self.install_sdk
        # If the gcloud executable exists, assume everything is fine.
        if File.exist?(GCLOUD)
          return
        end

        $stderr.puts "Downloading Google Cloud SDK"
        context.shell("wget #{BASE + NAME + EXT}")

        $stderr.puts "Extracting Google Cloud SDK"
        cmd = "tar xvf #{NAME + EXT} -C #{Dir.home}" # let tar decide which compression algorithm to use
        bootstrap_script = "#{Dir.home}/#{NAME}/bin/bootstrapping/install.py"
        run_command_and_wait_for_file(cmd, bootstrap_script)

        # Bootstrap the Google Cloud SDK.
        cmd = "env CLOUDSDK_CORE_DISABLE_PROMPTS=1 #{bootstrap_script} --usage-reporting=false --command-completion=false --path-update=false --additional-components=preview"

        $stderr.puts "Bootstrap Google Cloud SDK"
        run_command_and_wait_for_file(cmd, GCLOUD)
      end

      install_sdk

      def needs_key?
        false
      end

      def check_auth
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
