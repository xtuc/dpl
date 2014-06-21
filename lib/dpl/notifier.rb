require 'dpl/error'
require 'faraday'
require 'active_support/inflector'

module DPL
  class Notifier
    autoload :NewRelic, 'dpl/notifier/new_relic'

    def self.notify(opts)
      # 'opts' should be an array of hashes,
      # each having the notifier name as the key,
      # and the options has for that notifier as the value
      Array(opts).each do |notifier|
        notifier.each do |k, v|
          client = self.const_get(k.to_s.camelize).new
          client.notify(v)
        end
      end
    end
  end
end