module AuthCacheMethods

  def self.included base
    super
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

end


