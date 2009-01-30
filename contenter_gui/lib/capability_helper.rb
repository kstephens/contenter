module CapabilityHelper

  SEP = '/'.freeze

  def capability_expand cap_path
    (@@capability_expand ||= { })[cap_path] ||=
      begin
        x = _capability_expand(cap_path.split(SEP))
        x.uniq!
        x
      end
  end

  def _capability_expand cap_path
    return [ ] if cap_path.empty?

    c_first = cap_path.first
    pre_a = [ '*', c_first, '+' ]
    pre_a.uniq!

    c_rest = cap_path[1 .. -1]
    if c_rest.empty?
      pre_a
    else
      c_rest = _capability_expand(c_rest)
      pre_a.inject([ ]) do | result, pre |
        c_rest.each do | rest |
          result << (pre + SEP + rest)
        end
        result
      end
    end
  end

end


