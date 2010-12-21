# module Garm # FIXME

module AuthCacheMethods

  def self.included base
    super
    base.extend(ClassMethods)
    base.class_eval do 
      after_save :flush_cache!
      def flush_cache!
        AuthorizationCache.current.auth_changed!(self)
      end

      def self.auth_cache_delegate method
        self.class_eval <<"END", __FILE__, __LINE__
def #{method} *args
  AuthorizationCache.current.#{self.name}_#{method}(self, *args)
end
END
      end
    end
  end

  module ClassMethods
    include Garm::CapabilityExpand # capability_expand

    def all_with_capability cap
      result = [ ]
      caps = capability_expand(cap)
      all.each do | obj |
        obj = obj.class[obj.id] # force cached object.
        if obj.has_capability?(caps)
          result << obj
        end
      end
      result
    end
  end


  # Adds caching to belongs_to by redirecting queries through
  # the target class' :[] method, which must be implemented.
  #
  module BelongsTo
    def find_target
      @reflection.klass[@owner[@reflection.primary_key_name].to_i]
    end
  end

  # Adds caching to has_many by redirecting queries through
  # the target class' :[] method, which must be implemented.
  #
  module HasMany
    def find_target
      results = super
      # $stderr.puts "results =\n#{results.pretty_inspect}\n----"
      results.map!{|obj | @reflection.klass[obj.id]}
      results
    end
  end

end


