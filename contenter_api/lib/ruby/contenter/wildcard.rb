require 'contenter'

module Contenter
  # Transforms a String into an Array of String objects,
  # where each "<<THING>>" in the input String is enumerated by replacing and expanding it with:
  # [ "*", "<<THING>>", "+" ]
  # 
  # Multiple wildcards force multiple enumerations.
  #
  # This is used by the Contenter authorization framework for converting
  # capability queries like User#has_capability?("controller/<<<ctlr>>/<<action>>")
  # into mechanical searches for role capability rules like:
  # "controler/*/*" or "controller/show/+"
  #
  # This can also be used for wildcarding content keys by Contenter::Api modules or extensions.
  # 
  # See wildcard_spec.rb for examples.
  module Wildcard

    # Represents an early matching ANY pattern.
    ANY = '*'.freeze
    
    # Represents a later matching OTHER pattern.
    OTHER = '+'.freeze

    # Used for pattern elements with no wildcard element.
    NONE = [ ''.freeze ].freeze


    # Main interface.
    def enumerate_wildcard str
      elems = split_wildcard str
      enumerate_wildcard_1 elems
    end
    

    # Splits "prefix <<wild>> suffix" into
    # [ [ 'prefix ', 'wild' ], [ ' suffix', nil ] ]
    def split_wildcard str
      return str if Array === str # Str is already split.
      return [ [ '', nil ] ] if str.empty?
      result = str.scan(/([^<]*)(?:<<([^>]*)>>)?/)
      # result = result.map! { | x | x[1] == ANY || x[1] == OTHER ? [ x[0] + x[1], nil ] : x }
      if last = result[-1]
        result.pop if last[0].empty? && last[1].nil?
      end
      # $stderr.puts "split_wildcard #{str.inspect} => #{result.inspect}"
      result
    end


    def enumerate_wildcard_1 elems, n = 0
      return elems if elems.empty?
      first = elems[n]
      n += 1
      result = [ ]
      ((w = first[1]) ? uniq!([ ANY, w, OTHER ]) : NONE).each do | e |
        x = first[0] + e
        if elems[n]
          enumerate_wildcard_1(elems, n).each do | rest |
            result << (x + rest)
          end
        else
          result << x
        end
      end
      uniq!(result)
    end


    # Handles brace expansion similar to bash shell.
    #
    # Example:
    #   brace_expansion("pre {hello,world} post {1,2,3}") =>
    #  ["pre hello post 1", "pre hello post 2", "pre hello post 3", "pre world post 1", "pre world post 2", "pre world post 3"]
    #
    def brace_expansion str
      return [ ] unless str
      return str if Array === str # already expanded
      result = [ '' ]
      str = str.to_s
      while m = /\{([^\}]*)\}/.match(str)
        result.each{|x| x << m.pre_match}
        str = m.post_match
        unless (elems = m[1].split(',')).empty?
          new_result = [ ]
          result.each do | x |
            elems.each do | elem |
              new_result << (x + elem)
            end
          end
          result = new_result
        end
      end
      result.map!{|x| x + str} unless str.empty?
      result
    end

    def uniq! x
      x.uniq!
      x
    end

  end # module
end # module
