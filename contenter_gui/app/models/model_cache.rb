
# Generic model cache.
#
class ModelCache
  # Adds caching to belongs_to by redirecting queries through
  # the target class' :[] method, which must be implemented using ModelCache.
  # See ContentModel for examples.
  #
  module BelongsTo
    def find_target
      @reflection.klass[@owner[@reflection.primary_key_name].to_i]
    end
  end


  include ThreadVariable
  
  cattr_accessor_thread :current, :initialize => '[ ]'

  cattr_accessor_thread :enabled, :initialize => 'true'

  attr_accessor :enabled

  attr_accessor :n_flush, :n_check, :n_miss

  attr_reader :cache

  ENABLED = true
  ENABLED = false unless defined? ENABLED

  STATS_ENABLED = false
  STATS_ENABLED = true unless defined? STATS_ENABLED

  EMPTY_ARRAY = [ ].freeze
  EMPTY_HASH_MUTABLE = { } # MUTABLE!


  def initialize
    @enabled = true
    @cache = { }
    @n_flush = { }
    @n_check = 0
    @n_miss = 0
  end



  def n_hit
    @n_hit = @n_check - @n_miss
  end


  def stats
    n_hit
    [
     [ :flush,           @n_flush.map { | cls, h | [ cls.name, h ] } ],
     [ :check,           @n_check ],
     [ :hit,             @n_hit ],
     [ :miss,            @n_miss ],
     [ :hit_check_ratio, @n_check > 0 ? @n_hit.to_f / @n_check.to_f : 0 ],
     [ :slots,           @cache.map { | cls, h | [ cls.name, h.keys ] } ],
    ]
  end


  # Pushes a new ModelCache on the current stack.
  def self.create!
    self.current << new if ENABLED
  end


  # Removes all ModelCache objects from the current stack.
  def self.reset!
    self.clear_current
  end


  def self.flush! *args
    current.each do | cache |
      cache.flush! *args
    end
  end


  def self.with_current cache = nil
    if ENABLED
      cache = new if cache == nil
      raise TypeError, "expected #{self}, given #{cache.class}" unless self === cache
      self.current.push(cache)
    end
    yield cache
  ensure
    if ENABLED
      self.current.pop
    end
  end


  def self.register_model model_class
    return unless ENABLED
    model_class.class_eval do
      after_save :clear_model_cache!
      after_create :clear_model_cache!
      def clear_model_cache!
        ModelCache.flush!(self.class)
      end
    end
  end


  def flush! cls = nil, slot = nil, key = nil
    @n_flush[cls] ||= 0
    @n_flush[cls] += 1
    case
    when cls == nil && slot == nil && key == nil
      @cache.clear
    when cls != nil && slot == nil && key == nil
      (@cache[cls] || EMPTY_HASH_MUTABLE).clear
    when cls != nil && slot != nil && key != nil
      ((@cache[cls] || EMPTY_HASH_MUTABLE)[slot] || EMPTY_HASH_MUTABLE).clear
    else
      ((@cache[cls] || EMPTY_HASH_MUTABLE)[slot] || EMPTY_HASH_MUTABLE).delete(key)
    end
    self
  end


  def self.cache_for cls, slot, key
    if ENABLED && enabled && (cache = current[-1])
      cache._cache_for cls, slot, key do
        yield
      end
    else
      yield
    end
  end


  # DO NOT CALL THIS DIRECTLY.
  # Use ModelCache.cache_for
  def _cache_for cls, slot, key
    if @enabled
      (((@cache[cls] ||= { })[slot] ||= { })[key] ||= [ yield ]).first
    else
      yield
    end
  end


if STATS_ENABLED

  # DO NOT CALL THIS DIRECTLY.
  # Use ModelCache.cache_for
  def _cache_for cls, slot, key
    if @enabled
      @n_check += 1
      (((@cache[cls] ||= { })[slot] ||= { })[key] ||= [ yield(@n_miss += 1) ]).first
    else
      yield
    end
  end
end

end # class

