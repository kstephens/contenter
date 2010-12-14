# -*- ruby -*-


# Test Target:
require 'cabar/observer'

# Test Dependencies:
require 'pp'


describe 'Cabar::Observer' do
  module Cabar::Observer::Test
  end

  class Cabar::Observer::Test::Observed
    include Cabar::Observer::Observed

    attr_reader :some_action_args
    def clear!
      @some_action_args = nil
    end

    def some_action *args
      $stderr.puts "#{self.inspect} some_action #{args.inspect}"
      @some_action_args = args
      return true
    end
    notify_observers_before_method :some_action

    def some_action_2 *args
      $stderr.puts "#{self.inspect} some_action_2 #{args.inspect}"
      @some_action_args = args
      return true
    end
    notify_observers_after_method :some_action_2

    def some_action_3 *args
      $stderr.puts "#{self.inspect} some_action_3 #{args.inspect}"
      @some_action_args = args
      return true
    end
    notify_observers_around_method :some_action_3
  end

  class Cabar::Observer::Test::Observed1
    include Cabar::Observer::Observed
  end

  class Cabar::Observer::Test::Observed2 < Cabar::Observer::Test::Observed1
    include Cabar::Observer::Observed
  end


  class Cabar::Observer::Test::Observer
    attr_accessor :notified
    def initialize
      clear!
    end
    def clear!
      @notified = { }
    end
    def method_missing sel, *args
      (@notified[sel] ||= [ ]) << args
    end
  end


  it "should handle instance-based observations" do
    observed = Cabar::Observer::Test::Observed.new

    callback_obj = nil
    callback_args = nil
    observed.add_observer!(:test1) do | obj, *args |
      callback_obj = obj
      callback_args = args
    end
    observed.notify_observers!(nil, 1, 2)
    callback_obj.should == observed
    callback_args.should == [ 1, 2 ]

  end # it


  it "should handle observer objects" do
    observed = Cabar::Observer::Test::Observed.new
    observer = Cabar::Observer::Test::Observer.new

    observed.add_observer!(observer, :event, :update)

    observed.notify_observers!(:unknown_event, 1, 2)
    observer.notified[:update].should == nil

    observed.notify_observers!(:event, 1, 2)
    observer.notified[:update].should == [ [observed, 1, 2] ]

  end # it


  it "should handle implicit action arguments" do
    observed = Cabar::Observer::Test::Observed.new
    observer = Cabar::Observer::Test::Observer.new

    observed.add_observer!(observer, :event, [ :callback ])

    observed.notify_observers!(:unknown_event, 1, 2)
    observer.notified[:callback].should == nil

    observed.notify_observers!(:event, 1, 2)
    observer.notified[:callback].should == [ [observed, :event, 1, 2] ]

  end # it

  it "should handle implicit action arguments with Proc" do
    observed = Cabar::Observer::Test::Observed.new

    callback_calls = [ ]
    observed.add_observer!(:test2, :event, [ ]) do | obj, *args |
      callback_calls << [ obj, *args ]
    end
    observed.class.add_observer!(:test2, :event, [ ]) do | obj, *args |
      callback_calls << [ obj, *args ]
    end

    callback_calls = [ ]
    observed.notify_observers!(:unknown_event, 1, 2)
    callback_calls.should == [ ]

    callback_calls = [ ]
    observed.notify_observers!(:event, 1, 2)
    callback_calls.should == [ [ observed, :event, 1, 2 ], [ observed, :event, 1, 2 ] ]
  end # it

  it "should handle named instance-based observations" do
    observed = Cabar::Observer::Test::Observed.new

    callback_args = nil
    observed.add_observer!(:test2, :specific_event) do | obj, *args |
      callback_args = args
    end

    callback_args = nil
    observed.notify_observers!(:other_event, 1, 2)
    callback_args.should == nil

    callback_args = nil
    observed.notify_observers!(:specific_event, 3, 4)
    callback_args.should == [ 3, 4 ]

    callback_args = nil
    observed.notify_observers!(nil, 5, 6) # All actions.
    callback_args.should == [ 5, 6 ]

  end # it


  it "should handle multiple instance-based observations" do
    observed = Cabar::Observer::Test::Observed.new

    callback_args = { }
    observed.add_observer!(:test3) do | obj, *args |
      callback_args[:test3] = args
    end
    observed.add_observer!(:test4) do | obj, *args |
      callback_args[:test4] = args
    end

    observed.notify_observers!(nil, 1, 2)
    callback_args[:test3].should == [ 1, 2 ]
    callback_args[:test4].should == [ 1, 2 ]

    # pp observed.instance_variable_get("@instance_observed_manager")

    # Remove old an observer
    observed.delete_observer!(:test3)
    callback_args = { }

    # pp observed.instance_variable_get("@instance_observed_manager")

    observed.notify_observers!(nil, 1, 2)
    callback_args[:test3].should == nil
    callback_args[:test4].should == [ 1, 2 ]

  end # it


  it "should handle instance-based observations" do
    observed = Cabar::Observer::Test::Observed.new
 
    callback_obj = nil
    callback_args = nil
    observed.add_observer!(:test5) do | obj, *args |
      callback_obj = obj
      callback_args = args
    end
    observed.notify_observers!(nil, 1, 2)
    callback_obj.should == observed
    callback_args.should == [ 1, 2 ]

  end # it


  it "should handle instance-based observations with action names for wildcard actions with Proc callbacks" do
    begin
      # Cabar::Observer::Manager.verbose = true

      observed = Cabar::Observer::Test::Observed.new
      
      callback_calls = [ ]
      observed.add_observer!(:test5, nil, [ ]) do | obj, *args |
        callback_calls << [ obj.object_id, *args ]
      end
      observed.observed_managers.first.callback_by_action[nil].should_not == nil
      
      observed.notify_observers!(nil, 1, 2)
      observed.notify_observers!(:foo, 3)
      observed.notify_observers!(:bar)
      callback_calls.should == [ [ observed.object_id, nil, 1, 2 ], [ observed.object_id, :foo, 3 ], [ observed.object_id, :bar ] ]
    ensure
      # Cabar::Observer::Manager.verbose = false
    end
  end # it


  it "should handle instance-based observations with action names for wildcard actions with observer object callbacks" do
    begin
      # Cabar::Observer::Manager.verbose = true

      observed = Cabar::Observer::Test::Observed.new
      observer = Cabar::Observer::Test::Observer.new
      
      observed.add_observer!(observer, nil, [ :callback2 ])
      observed.observed_managers.first.callback_by_action[nil].should_not == nil
      
      observed.notify_observers!(nil, 1, 2)
      observed.notify_observers!(:foo, 3)
      observed.notify_observers!(:bar)
      observer.notified[:callback2].should == [ [ observed, nil, 1, 2 ], [ observed, :foo, 3 ], [ observed, :bar ] ]
    ensure
      # Cabar::Observer::Manager.verbose = false
    end
  end # it


  it "should handle named class-based observations" do
    begin
      observed = Cabar::Observer::Test::Observed.new
      observed2 = Cabar::Observer::Test::Observed.new
      
      callback_obj = [ ]
      callback_args = [ ]
      observed.class.add_observer!(:test6, :specific_event) do | obj, *args |
        # pp [ :test6, obj, args ]
        callback_obj  << obj
        callback_args << args
      end
      
      callback_obj = [ ]
      callback_args = [ ]
      observed.notify_observers!(:other_event, 1, 2)
      observed2.notify_observers!(:other_event, 3, 4)
      callback_obj.should == [ ]
      callback_args.should == [ ]
      
      callback_obj = [ ]
      callback_args = [ ]
      observed.notify_observers!(:specific_event, 5, 6)
      observed2.notify_observers!(:specific_event, 7, 8)
      callback_obj.should == [ observed, observed2 ]
      callback_args.should == [ [ 5, 6 ], [ 7, 8 ] ]
    ensure
      observed.class.delete_observer!(:test6, :specific_event)
    end
  end# it


  it "should handle inheirited class-based observations" do
    begin
      observed1 = Cabar::Observer::Test::Observed1.new
      observed2 = Cabar::Observer::Test::Observed2.new
      
      callback_args = [ ]
      observed1.class.add_observer!(:test6_1, :specific_event) do | obj, *args |
        # pp [ :test6_2, obj, args ]
        callback_args << [ :test6_1, obj, args ]
      end
      observed2.class.add_observer!(:test6_2, :specific_event) do | obj, *args |
        # pp [ :test6_2, obj, args ]
        callback_args << [ :test6_2, obj, args ]
      end
      observed2.add_observer!(:test6_3, :specific_event) do | obj, *args |
        # pp [ :test6_3, obj, args ]
        callback_args << [ :test6_3, obj, args ]
      end
      
      callback_args = [ ]
      observed2.notify_observers!(:specific_event, 5, 6)
      callback_args.should == [ 
                               [ :test6_3, observed2, [ 5, 6 ] ], 
                               [ :test6_2, observed2, [ 5, 6 ] ], 
                               [ :test6_1, observed2, [ 5, 6 ] ], 
                              ]
    ensure
      observed1.class.delete_observer!(:test6_1, :specific_event)
      observed2.class.delete_observer!(:test6_2, :specific_event)
    end
  end# it



  it "should handle class- and instance-based observations" do
    begin
      observed = Cabar::Observer::Test::Observed.new
      observed2 = Cabar::Observer::Test::Observed.new
      
      callback_obj = [ ]
      callback_args = [ ]
      observed.class.add_observer!(:test7, :specific_event) do | obj, *args |
        # pp [ :test6, obj, args ]
        callback_obj  << obj
        callback_args << args
      end
      observed2.add_observer!(:test8, :specific_event) do | obj, *args |
        # pp [ :test6, obj, args ]
        callback_obj  << obj
        callback_args << args
      end
      
      callback_obj = [ ]
      callback_args = [ ]
      observed.notify_observers!(:other_event, 1, 2)
      observed2.notify_observers!(:other_event, 3, 4)
      callback_obj.should == [ ]
      callback_args.should == [ ]
      
      callback_obj = [ ]
      callback_args = [ ]
      observed.notify_observers!(:specific_event, 5, 6)
      observed2.notify_observers!(:specific_event, 7, 8)
      callback_obj.should == [ observed, observed2, observed2 ]
      callback_args.should == [ [ 5, 6 ], [ 7, 8 ], [ 7, 8] ]
    ensure
      observed.class.delete_observer!(:test7, :specific_event)
    end
  end # it



end # describe
