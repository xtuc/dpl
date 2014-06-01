require 'dpl/error'
require 'dpl/provider'

module DPL
  class CLI
    def self.run(*args)
      new(args).run
    end

    OPTION_PATTERN = /\A--([a-z][a-z_\.\-]*)(?:=(.+))?\z/
    attr_accessor :options, :fold_count

    def initialize(*args)
      options = {}
      args.flatten.each do |arg|
        next options.update(arg) if arg.is_a? Hash
        die("invalid option %p" % arg) unless match = OPTION_PATTERN.match(arg)

        keys = match[1].tr('-', '_').split(/\./).map(&:to_sym)
        value = match[2]
        assign_value(options, keys, value)
      end

      self.fold_count = 0
      self.options    = default_options.merge(options)
    end

    def run
      provider = Provider.new(self, options)
      provider.deploy
    rescue Error => error
      options[:debug] ? raise(error) : die(error.message)
    end

    def fold(message)
      self.fold_count += 1
      print "travis_fold:start:dpl.#{fold_count}\r" if options[:fold]
      puts "\e[33m#{message}\e[0m"
      yield
    ensure
      print "\ntravis_fold:end:dpl.#{fold_count}\r" if options[:fold]
    end

    def default_options
      {
        :app      => File.basename(Dir.pwd),
        :key_name => %x[hostname].strip
      }
    end

    def shell(command)
      system(command)
    end

    def die(message)
      $stderr.puts(message)
      exit 1
    end

    private

    # given a hash, keys array = [:key1, :key2, :key3, …],
    # and a value, do:
    # hash[:key1][:key2][:key3]… = value
    def assign_value(hash, keys, value)
      sarrogate = hash

      while keys.length > 0 do
        next_key = keys.shift
        if sarrogate.include? next_key
          # we have seen this key before
          if keys.length > 0
            # go deeper
            sarrogate = sarrogate[next_key]
          else
            # there is no other key, so push value to the end of array
            sarrogate[next_key] = Array(sarrogate[next_key]) << value
          end
        else
          # we haven't seen this key before
          if keys.length > 0
            # go deeper
            sarrogate[next_key] ||= {}
            sarrogate = sarrogate[next_key]
          else
            # assign value
            sarrogate[next_key] = value || true
          end
        end
      end
    end
  end
end
