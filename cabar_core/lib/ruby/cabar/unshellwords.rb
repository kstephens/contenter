module Cabar
  module Unshellwords

    # Converts an array of shellwords into
    # an escaped shellword String.
    #
    def unshellwords(words, opts = { })
      return words if String === words
      
      if opts[:quote]
        opts[:quote_glob] = true 
        opts[:quote_var] = true
        opts[:quote_comment] = true
      end
      
      result = words.collect do | x |
        y = x.gsub(/([\\"])/) { | m | '\\' + m }
        if y.empty? || # empty string => ""
            y != x ||   # Needed quote escapes
            (opts[:quote_glob]    && /[\[\]\?\*]/.match(y)) ||
            (opts[:quote_var]     && /[\$]/.match(y)) ||
            (opts[:quote_comment] && /[\#]/.match(y))
          x = '"' + y + '"'
        end
        x
      end.join(' ')
      
      result
    end # def
    
  end # module
end # module

