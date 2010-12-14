
class Hash
  # { :a => 1, :b => 2, :c => 3 }.project(:a, :c) == { :a => 1, :c => 3 }
  def project(*elems)
    elems = elems.first if Enumerable === elems.first
    h = { }
    elems.each { | k | h[k] = self[k] }
    h
  end
end

class Hash
  module OrderedKey
    def self.extend_object(obj)
      raise TypeError, "expected Hash, given #{obj.class.name}" unless Hash === obj
      super
      meth = obj.class.instance_method(:keys)
      (class << obj; self; end).send(:define_method, :unordered_keys, meth)
    end

    attr_accessor :ordered_keys

    def keys
      @ordered_keys || 
        unordered_keys.sort { | a, b | compare_keys(a, b) }
    end

    def each
      keys.each do | k |
        yield k, self[k]
      end
    end

    def compare_keys a, b
      case
=begin
      when Comparable === a && ! Comparable === b
        -1
      when ! Comparable === a && Comparable === b
        1
=end
      when Numeric === a && Numeric === b
        a <=> b
      when Numeric === a && ! Numeric === b
        a.to_s <=> b.to_s
      when ! Numeric === a && Numeric === b
        a.to_s <=> b.to_s
      when Comparable === a && Comparable === b && a.class === b
        a <=> b
      when Symbol === a || Symbol === b
        a.to_s <=> b.to_s
      when String === a || String === b
        a.to_s <=> b.to_s
      when
        a.object_id <=> b.object_id
      end
    end
  end
end

