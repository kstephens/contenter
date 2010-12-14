require 'yaml'

module Contenter
  module Yaml
    # Work around whitespace and newline issues with String.to_yaml
    #
    # Assumes that this result will be terminated with a single newline in the YAML
    # document it is embedded in.
    TILDE = '~'.freeze

    def string_as_yaml str, indent = nil
      return TILDE if str.nil?
      indent ||= ''
      
      str_has_leading_whitespace = /\A\s+/.match(str)
      str_has_trailing_whitespace = /[ \t]\Z/.match(str)
      str_has_trailing_newline = /(\r?\n)\Z/.match(str)

      if str.empty? || str_has_leading_whitespace || str_has_trailing_whitespace
        str.inspect
      else
        if str_has_trailing_newline
          str = str.sub(/(\r?\n)\Z/, '')
        end
        "|#{str_has_trailing_newline ? '+' : '-'}\n#{indent}#{str.gsub(/(\r?\n)/){|x| x << indent}}"
      end
    end

    extend self

  end
end
