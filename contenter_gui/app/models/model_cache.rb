
class ModelCache
  include ThreadVariable
  
  cattr_accessor_thread :current, :default => 'new'

  def initialize
    @cache = { }
  end


  def flush
    @cache.clear
  end


  def cache_for cls, key, value
    ((@cache[cls] ||= { })[key] ||= { })[value] ||=
      yield
  end

end # class

