
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
  # Adds ordered key behavior to Hashes.
  module OrderedKey
    def self.extend_object(obj)
      raise TypeError, "expected Hash, given #{obj.class.name}" unless Hash === obj
      super
      meth = obj.class.instance_method(:keys)
      (class << obj; self; end).send(:define_method, :unordered_keys, meth)
    end

    attr_accessor :ordered_keys

    # Returns @ordered_keys if defined, otherwise returns
    # keys sorted via compare_keys.
    def keys
      @ordered_keys || 
        unordered_keys.sort { | a, b | compare_keys(a, b) }
    end

    # Yields key/value pairs based on sorted keys.
    def each
      keys.each do | k |
        yield k, self[k]
      end
    end

    # Compare key objects heterogeneously using class_metric 
    # as a tie breaker for disjoint types.
    def compare_keys a, b
      case
      when Numeric === a && Numeric === b
        a <=> b
      when Comparable === a && Comparable === b && a.class === b
        a <=> b
      when String === a && String === b
        a <=> b
      when Symbol === a && Symbol === b
        a.to_s <=> b.to_s
      end ||
        (class_metric(a) <=> class_metric(b)).nonzero? || 
        a.object_id <=> b.object_id
    end

    # Assign a sort metric based on object's class.
    def class_metric obj
      case obj
      when nil
        0
      when true, false
        1
      when Numeric
        2
      when Symbol
        3
      when String
        4
      else
        5
      end
    end

  end
end

