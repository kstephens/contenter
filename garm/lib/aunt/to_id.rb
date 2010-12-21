
class Object
  def to_id
    nil
  end
end

class Integer
  def to_id
    self
  end
end

if defined? ::ActiveRecord
  class ActiveRecord::Base
    alias :to_id :id
  end
end

