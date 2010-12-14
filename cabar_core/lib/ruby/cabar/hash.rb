=begin rdoc

Extensions for Ruby Hash for Cabar.

=end

class ::Hash
  def cabar_symbolify!
    each do | k, v |
      if String === k
        self[k.to_sym] = v
      end
    end
    keys.each do | k |
      delete(k) if String === k
    end
    self
  end

  def cabar_symbolify
    dup.cabar_symbolify!
  end

  def cabar_merge! h, path = [ ]
    case h
    when Hash
      h.each do | k, v |
        self[k] = v
        case v
        when Hash
          self[k].cabar_merge! v, path + [ k ]
        end
      end
    else
      raise ArgumentError, "expected Hash at #{path.join('.')}, given #{h.class}"
    end
    self
  end
end

