
class Object
  alias :to_s_const :to_s
end

class Symbol
  # Avoid creating String garbage objects when
  # needing a read-only String representation of a Symbol.
  def to_s_const
    @to_s_const ||= to_s.freeze
  end
end


