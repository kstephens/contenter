module Garm
  module Api
    def self.lib_dir
      @@lib_dir ||= File.expand_path("../..", __FILE__).freeze
    end

    # Returns the current Thread's instance.
    def self.current
      Thread.current[:'Garm::Api.current'] ||=
        (@@current ||=
         new)
    end

    def self.new
      Garm::Api::Arb.new # HACK
    end
  end
end

require 'garm/api/base'

