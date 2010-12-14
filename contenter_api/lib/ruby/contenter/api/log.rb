require 'contenter/api'

module Contenter
  class Api
    # Support class for logging.
    module Log
      # The logger object to use.
      attr_accessor :logger

      # Log for debugging.
      def log level, msg = nil
        case
        when @logger
          msg ||= yield if block_given?
          @logger.send(level, msg)
        when @api
          msg ||= yield if block_given?
          @api.log level, msg
        when level != :debug
          msg ||= yield if block_given?
          $stderr.puts "  #{self} #{level} #{msg}"
        end
      end

      # Avoid too much output in IRB.
      def inspect
        "#<#{self.class} #{(@name || object_id).inspect}>"
      end

    end # class
  end # class
end # module

