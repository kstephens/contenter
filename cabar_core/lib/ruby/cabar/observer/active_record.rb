require 'cabar/observer'

module Cabar
  module Observer
    # Adds Cabar::Observer notifications for ActiveRecord lifecycle callbacks.
    module ActiveRecord
      def self.included target
        super
        # return if target.ancestors.include?(Cabar::Observer::Observed)
        target.class_eval do
          # $stderr.puts "  ### #{target}.include Cabar::Observer::ActiveRecord"
          include Cabar::Observer::Observed
        end

        [ :before, :after ].each do | time |
          [ :validation, :save, :destroy ].each do | event |
            callback = :"#{time}_#{event}"
            method = :"notify_#{callback}!"
            target.class_eval(<<"END", __FILE__, __LINE__)
def #{method}
  notify_observers!(#{callback.inspect})
end
#{callback} #{method.inspect}
END
          end            
        end
      end #def
    end # module
  end # module
end # module

