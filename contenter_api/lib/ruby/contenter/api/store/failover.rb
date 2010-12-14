require 'contenter/api/store'

require 'contenter/failover_delegate'

module Contenter
  class Api
    class Store
      # See Contenter::FailoverDelegate for more information.
      class Failover < self
        include Contenter::FailoverDelegate::Behavior

        def initialize opts
          on_error = lambda { | delegate_h, error, method, args |
            self.log(:error) { "#{self.class.name}: #{delegate_h[:delegate].name} #{method.inspect} #{error.inspect}\n#{error.backtrace * "\n"}" }
          }
          opts[:on_error] ||= on_error
=begin
          Contenter::FailoverDelegate.new(:delegates => opts[:delegates], 
                                            :on_error => opts[:on_error] || on_error)
=end
          super
        end


        # Interface for API#get.
        #
        # Returns a Content or nil.
        def get(type, key, sel)
          with_delegate! do | d |
            d[:delegate].get(type, key, sel)
          end
        end


        # Interface for API#enumerate.
        #
        # Returns Array of [ Key, Source Selector ]
        def enumerate(type, opts, selector)
          with_delegate! do | d |
            d[:delegate].enumerate(type, opts, selector)
          end
        end


        def preload!
          @delegates.each do | d |
            d[:delegate].preload!
          end
          self
        end


        def reload!
          @delegates.each do | d |
            d[:delegate].reload!
          end
          self
        end


        # Called from Contenter::Api#invalidate_cache!
        def invalidate_cache! now = nil
          now ||= self.now
          check_blacklisted_delegate_intervals!(now)
        end

      end # class
    end # class
  end # class
end # module

