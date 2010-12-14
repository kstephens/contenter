
module Cabar
  # A better observer module.
  # Supports multiple actions and callback methods per observer.
  # Callbacks can be method names or Procs.
  # Supports observers of all instances of a class or
  # single instances.
  module Observer
    class Manager
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

      # FIXME!!
      #def dup
      #end

      # Adds an observer for an action.
      # If action is nil, the observer observes all actions.
      # callback can be a Proc or a method Symbol.
      def add_observer observer, action = nil, callback = nil
        # $stderr.puts "add_observer on #{@owner.class.inspect} #{observer} #{action} #{callback}"
        callback ||= action || :update 
        callback = [ observer, callback ]
        (@callback_by_action[action] ||= [ ]).push callback
      end

      # Removes observer as a notifee for action.
      # If action is nil, observer is removed for all actions.
      def delete_observer observer, action = nil
        action ||= [ @observers_by_action.keys ]
        action = [ action ] unless Array === action
        action.map{|x| @callback_by_action[x]}.each do | callbacks |
          callbacks.reject! do | callback |
            callback[0] == observer
          end
        end
      end

      # Removes all observers.
      def delete_observers
        @callback_by_action.clear
      end

      # Notify all observers of action with *args.
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
      def notify_observers observed, action, args
        action ||= [ @observers_by_action.keys ]
        action = [ action ] unless Array === action
        action = action.dup
        action.push nil # ALL ACTIONS

        callback_by_action = @callback_by_action.dup
        notifying = @notifying

        action.each do | action |
          next if notifying[action] && notifying[action] > 0
          begin
            notifying[action] ||= 0
            notifying[action] += 1

            (callback_by_action[action] || EMPTY_ARRAY).each do | callback |
              observer = callback[0]
              callback = callback[1]
              # $stderr.puts "notify #{observer} #{observed} #{callback.inspect} #{args.inspect}"
              case callback
              when Proc
                callback.call(observed, *args)
              else
                observer.send(callback, observed, *args)
              end
            end

          ensure
            notifying[action] -= 1
          end
        end
      end
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
    #         notify_observers(:name_changing, @name)
    #         @name = x
    #         notify_observers(:name_changed, @name)
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
    #       obj.add_observer(self, :name_changing)
    #       obj.add_observer(self, Proc.new do | observer, new_name |
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

      module ClassMethods
        # Adds an observer for all instances of a class.
        def add_observer observer, action = nil, callback = nil, &blk
          callback ||= blk if block_given?
          @class_observed_manager ||= 
            Manager.new(self)
          @class_observed_manager.add_observer(observer, action, callback)
        end

        # Removes an observer for all instance of a class for an action.
        # If action is nil, observer is removed for all actions.
        def delete_observer observer, action = nil
          @class_observed_manager && 
            @class_observed_manager.delete_observer(observer, action)
        end

        # Removes all observers on all instances of a class.
        # Observers on specific instances are not affected.
        def delete_observers
          @class_observed_manager && 
            @class_observed_manager.delete_observers
        end

        # Notifies all observers based on action passing *args.
        # If action is nil, all observers are notified.
        def notify_observers observed, action = nil, *args
          @class_observed_manager && 
            @class_observed_manager.notify_observers(observed, action, args)
        end
      end

      # Adds an observer for a specific action on an instance.
      # Callback can be a Proc or method Symbol.
      def add_observer observer, action = nil, callback = nil, &blk
        callback ||= blk if block_given?
        @instance_observed_manager ||= 
          Manager.new(self)
        @instance_observed_manager.add_observer(observer, action, callback)
      end

      # Removes an observer for an action on an instance.
      # If action is nil, observer is removed for all actions.
      def delete_observer observer, action = nil
        @instance_observed_manager &&
          @instance_observed_manager.delete_observer(observer, action)
      end

      # Removes all observers on an instance.
      # Observers on the class are still active.
      def delete_observers
        @instance_observed_manager && 
          @instance_observed_manager.delete_observers
      end

      # Notifies all observers on an instance with
      # an action and *args.
      # If action is nil, all observers are notified.
      # Class observers are notified after instance observers.
      def notify_observers action = nil, *args
        @instance_observed_manager && 
          @instance_observed_manager.notify_observers(self, action, args)
        self.class.notify_observers(self, action, args)
      end

    end
  end
end
