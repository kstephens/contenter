
module Cabar
  # A better observer module.
  # Supports multiple actions and callback methods per observer.
  # Callbacks can be method names or Procs.
  # Supports observers of all instances of a class or
  # single instances.
  module Observer
    EMPTY_ARRAY = [ ].freeze unless defined? EMPTY_ARRAY

    class Manager
      @@verbose = false
      def self.verbose; @@verbose; end
      def self.verbose=x; @@verbose = x; end

      attr_reader :owner

      attr_accessor :observed

      attr_reader :callback_by_action

      # Lock on each action during notify
      attr_reader :notifying

      EMPTY_ARRAY = [ ].freeze

      def initialize owner = nil
        super()
        @owner = owner
        @callback_by_action = { }
        @notifying = { }
      end

      
      def dup
        super.deepen_dup!
      end
      
      
      def deepen_dup!
        @owner = nil
        @callback_by_action = @callback_by_action.dup
        @notifying = { }
        self
      end


      # Adds an observer for an action.
      # If action is nil, the observer observes all actions.
      # callback can be a Proc or a method Symbol.
      def add_observer! observer, action, callback
        $stderr.puts "add_observer! #{@owner.class.inspect} #{observer} #{action.inspect} #{callback.inspect}" if @@verbose
        raise ArgumentError, "callback not specified" unless callback
        callback = [ observer, callback ]
        action = [ action ] unless Array === action
        action.each do | a |
          (@callback_by_action[a] ||= [ ]) << callback
        end
      end
      alias :add_observer :add_observer! # OLD API

      # Removes observer as a notifee for action.
      # If action is nil, observer is removed for all actions.
      def delete_observer! observer, action = nil
        action ||= @callback_by_action.keys.to_a
        action = [ action ] unless Array === action
        action.map{|a| @callback_by_action[a]}.each do | callbacks |
          next unless callbacks
          callbacks.delete_if do | callback |
            callback[0] == observer
          end
        end
      end
      alias :delete_observer :delete_observer! # OLD API

      # Removes all observers for an action.
      # If action is nil, all observers are removed for all actions.
      def delete_observers! action = nil
        case action
        when nil
          @callback_by_action.clear
        when Array
          action.each { | a | @callback_by_action.delete(a) }
        else
          @callback_by_action.delete(action)
        end
      end
      alias :delete_observers :delete_observers! # OLD API

      # Notify all observers of action with *args.
      #
      # If the callback is an Array,
      # the callback is the first element of the Array,
      # and the action is added to the front of the *args.
      #
      # If the callback registered for an observer is
      # a Proc, it is invoked as:
      #
      #   callback.call(observed, *args)
      #
      # If the callback is a not a Proc, it is invoked as:
      #
      #   observer.send(callback, observed, *args)
      #
      # If action is nil, observers of all actions are notified.
      #
      def notify_observers! observed, action, args = nil
        args ||= EMPTY_ARRAY
        actual_action = action
        action ||= @callback_by_action.keys.to_a
        action = [ action ] unless Array === action

        # Prepare to notify observers that want ALL ACTIONS.
        unless action.include?(nil) 
          action = action.dup
          action << nil 
        end
        
        $stderr.puts "  ### notify actions = #{action.inspect}" if @@verbose

        # Avoid side-effects if callbacks deregister observers.
        callback_by_action = @callback_by_action.dup

        # Avoid recursion if callback cause other events.
        notifying = @notifying
        
        action.each do | a |
          next if notifying[a] && notifying[a] > 0
          begin
            notifying[a] ||= 0
            notifying[a] += 1
            
            $stderr.puts "  ### callbacks for action #{a.inspect} => #{callback_by_action[a].inspect}" if @@verbose

            (callback_by_action[a] || EMPTY_ARRAY).each do | callback |
              observer, callback = *callback

              # If callback is an Array,
              # extract the callback from first element,
              # add the action to the front of the args.
              callback_args =
                case callback
                when Array
                  callback = callback.first
                  [ actual_action, *args ]
                else
                  args
                end

              $stderr.puts "  ### notify #{observer} #{observed} #{callback.inspect} #{callback_args.inspect}" if @@verbose
              case callback
              when Proc
                callback.call(observed, *callback_args)
              else
                observer.send(callback, observed, *callback_args)
              end
            end
            
          ensure
            notifying.delete(a) if (notifying[a] -= 1) <= 0
          end
        end
      end
      alias :notify_observers :notify_observers!
    end
   
    # Mixin for observed objects.
    #
    # Example:
    #
    #   class MyObserved
    #     include Cabar::Observed
    #
    #     def name=(x)
    #       if @name != x
    #         notify_observers!(:name_changing, @name)
    #         @name = x
    #         notify_observers!(:name_changed, @name)
    #       end
    #     end
    #   end
    #
    #   class MyObserver
    #     def name_changing observed, old_name
    #        puts "#{observed.inspect} name changing from #{old_name.inspect}
    #     end
    #     def name_changed observed, new_name
    #        puts "#{observed.inspect} name changed to #{new_name.inspect}
    #     end
    #     def observer obj
    #       obj.add_observer!(self, :name_changing)
    #       obj.add_observer!(self, Proc.new do | observer, new_name |
    #         puts "#{observed.inspect} name changed to #{new_name.inspect}
    #       end
    #     end
    #   end
    #
    #   x = MyObserved.new
    #   x.name = :foo
    #   y = MyObserver.new
    #   y.observe x
    #   x.name = :bar
    #
    module Observed
      def self.included(base)
        super
        base.extend ClassMethods
      end

      attr_reader :instance_observed_manager

      # Returns a Hash of Module name to Cabar::Observer::Manager.
      def self.observed_modules
        @observed_modules ||= { }
      end

      def class_observed_manager
        self.class.class_observed_manager
      end

      module ClassMethods
        def class_observed_manager
          Observed.observed_modules[self.name]
        end

        # Adds an observer for all instances of a class.
        def add_observer! observer, action = nil, callback = nil, &blk
          if block_given?
            if callback == EMPTY_ARRAY
              callback = [ blk ] 
            else
              callback ||= blk
            end
          end

          mgr = (Observed.observed_modules[self.name] ||= 
                 Manager.new(self))
          mgr.add_observer!(observer, action, callback)
        end
        alias :add_observer :add_observer! # OLD API

        # Removes an observer for all instance of a class for an action.
        # If action is nil, observer is removed for all actions.
        def delete_observer! observer, action = nil
          (mgr = class_observed_manager) && 
            mgr.delete_observer!(observer, action)
        end
        alias :delete_observer :delete_observer! # OLD API

        # Removes all observers on all instances of a class.
        # Observers on specific instances are not affected.
        def delete_observers!
          (mgr = class_observed_manager) && 
            mgr.delete_observers!
        end
        alias :delete_observers :delete_observers! # OLD API

        # Notifies all observers based on action passing *args.
        # If action is nil, all observers are notified.
        def notify_observers! observed, action = nil, *args
          (mgr = class_observed_manager) && 
            mgr.notify_observers!(observed, action, args)
        end
        alias :notify_observers :notify_observers! # OLD API


        # Redefine a method to notify observers before the method 
        # body is executed.
        def notify_observers_before_method method, action = nil
          action ||= :"before_#{method}"
          old_method = "without_notify_observers_#{method}"
          class_eval(<<"END", __FILE__, __LINE__)
            alias :#{old_method} :#{method} unless method_defined?(:#{old_method})
            def #{method}(*__args)
              notify_observers!(#{action.inspect}, *__args)
              send(:#{old_method}, *__args)
            end
END
        end

        # Redefine a method to notify observers after the method 
        # body is executed.
        def notify_observers_after_method method, action = nil
          action ||= :"after_#{method}"
          old_method = "without_notify_observers_#{method}"
          class_eval(<<"END", __FILE__, __LINE__)
            alias :#{old_method} :#{method} unless method_defined?(:#{old_method})
            def #{method}(*__args)
              __result = send(:#{old_method}, *__args)
              notify_observers!(#{action.inspect}, *__args)
              __result
            end
END
        end

        # Redefine a method to notify observers before and after the method 
        # body is executed.
        def notify_observers_around_method method, before_action = nil, after_action = nil
          before_action ||= :"before_#{method}"
          after_action ||= :"after_#{method}"
          old_method = "without_notify_observers_#{method}"
          class_eval(<<"END", __FILE__, __LINE__)
            alias :#{old_method} :#{method} unless method_defined?(:#{old_method})
            def #{method}(*__args)
              notify_observers!(#{before_action.inspect}, *__args)
              __result = send(:#{old_method}, *__args)
              notify_observers!(#{after_action.inspect}, *__args)
              __result
            end
END
         end

      end

      
      # Includers of this module.
      # should call this on the 
      # result of self.dup.
      def observed_deepen_dup!
        @instance_observed_manager = nil
        self
      end


      # Adds an observer for a specific action on an instance.
      # Callback can be a Proc or method Symbol.
      def add_observer! observer, action = nil, callback = nil, &blk
        if block_given?
          if callback == EMPTY_ARRAY
            callback = [ blk ] 
          else
            callback ||= blk
          end
        end

        @instance_observed_manager ||= 
          Manager.new(self)
        @instance_observed_manager.add_observer!(observer, action, callback)
        self
      end
      alias :add_observer :add_observer! # OLD API

      # Removes an observer for an action on an instance.
      # If action is nil, observer is removed for all actions.
      def delete_observer! observer, action = nil
        @instance_observed_manager &&
          @instance_observed_manager.delete_observer!(observer, action)
        self
      end
      alias :delete_observer :delete_observer! # OLD API

      # Removes all observers on an instance.
      # Observers on the class are still active.
      def delete_observers!
        @instance_observed_manager && 
          @instance_observed_manager.delete_observers!
        self
      end
      alias :delete_observers :delete_observers! # OLD API

      # Notifies all observers on an instance with
      # an action and *args.
      # If action is nil, all observers are notified.
      # Class observers are notified after instance observers.
      def notify_observers! action = nil, *args
        observed_managers.each do | mgr |
          mgr.notify_observers!(self, action, args)
        end
        self
      end
      alias :notify_observers :notify_observers! # OLD API

      # Returns an Array of Observer::Manager objects for this instance.
      # Includes any managers for any ancestors of the class of this object.
      def observed_managers
        result = [ ]
        result << @instance_observed_manager if @instance_observed_manager
        self.class.ancestors.each do | mod |
          mgr = Observed.observed_modules[mod.name]
          result << mgr if mgr
        end
        result
      end

    end # module
  end # module
end # module
