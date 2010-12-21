module Garm
  module Api
    def self.lib_dir
      @@lib_dir ||= File.expand_path("../..", __FILE__).freeze
    end
  end
end

