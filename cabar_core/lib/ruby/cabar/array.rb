=begin rdoc

Extensions for Ruby Array for Cabar.

=end

class ::Array 
  def cabar_uniq_return!
    uniq!
    self
  end

  def cabar_flatten_return!
    flatten!
    self
  end

  def cabar_each! 
    until empty?
      yield shift
    end
  end
end

