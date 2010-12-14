
require 'contenter/failover_delegate'

describe "Contenter::FailoverDelegate" do
  module Contenter
    class FailoverDelegate
      module Test
        class FailingDelegate
          attr_accessor :err, :msg
          def initialize name
            @name = name
          end

          def method_missing sel, *args
            self.msg = "#{@name} #{sel} #{args * " "} #{@err}"
            # $stderr.puts msg
            raise @err, self.msg if @err
            @name
          end
        end
      end
    end
  end #

  FailingDelegate = Contenter::FailoverDelegate::Test::FailingDelegate

  before(:each) do 
    @d1 = FailingDelegate.new(:d1)
    @d2 = FailingDelegate.new(:d2)
    @d3 = FailingDelegate.new(:d3)

    @on_error_dh = @on_error_error = nil
    @on_error = lambda { | dh, error, sel, args |
      (Hash === dh).should == true
      (Exception === error).should == true
      (sel.nil? || Symbol === sel).should == true
      (args.nil? || Array === args).should == true
      @on_error_dh = dh
      @on_error_error = error
      
    }
    @fd = Contenter::FailoverDelegate.
      new(:delegates => [
                         @dh1 = { :delegate => @d1, :blacklist_interval => 10 },
                         @dh2 = { :delegate => @d2, :blacklist_interval => 5 },
                         @dh3 = { :delegate => @d3, },
                       ],
          :on_error => @on_error)
    @now = Time.now
    @fd.instance_variable_set("@_now", @now)
  end

  it "should delegate to first delegate" do
    @on_error_dh = @on_error_error = nil

    @fd.do_it.should == :d1

    @on_error_dh.should == nil
    @on_error_error.should == nil

    @d1.msg.should == "d1 do_it  " 
    @d2.msg.should == nil
    @d3.msg.should == nil
  end

  it "should delegate to second delegate if first fails, and renabled after blacklist interval" do
    @on_error_dh = @on_error_error = nil

    @d1.err = ArgumentError

    @fd.do_it(1, 2).should == :d2

    @on_error_dh.should_not == nil
    @on_error_error.should_not == nil

    @d1.msg.should == "d1 do_it 1 2 ArgumentError" 
    @d2.msg.should == "d2 do_it 1 2 " 
    @d3.msg.should == nil
    @dh1[:last_error][:time].should_not == nil
    @dh1[:last_error][:method].should == :do_it
    @dh1[:last_error][:args].should == [ 1, 2 ]
    @dh1[:last_error][:error].class.should == ArgumentError
    @dh1[:blacklist_until].should == @now + @dh1[:blacklist_interval]
    @fd.available_delegates.should == [ @dh2, @dh3 ]
    @fd.blacklisted_delegates.should == [ @dh1 ]

    @now += 100
    @fd.instance_variable_set("@_now", @now)
    @fd.check_blacklisted_delegate_intervals!
    @dh1[:blacklist_until].should == nil
    @fd.available_delegates.should == [ @dh1, @dh2, @dh3 ]
    @fd.blacklisted_delegates.should == [ ]

    @d1.msg = @d2.msg = @d3.msg = nil
    @d1.err = nil
    @fd.do_it(1, 2).should == :d1
  end

  it "should delegate to third delegate if first and second fail, and reraise error if third fails" do
    @d1.err = ArgumentError
    @d2.err = ArgumentError

    @fd.do_it(1, 2).should == :d3

    @d1.msg.should == "d1 do_it 1 2 ArgumentError" 
    @d2.msg.should == "d2 do_it 1 2 ArgumentError" 
    @d3.msg.should == "d3 do_it 1 2 "

    @dh1[:last_error][:time].should_not == nil
    @dh1[:last_error][:method].should == :do_it
    @dh1[:last_error][:args].should == [ 1, 2 ]
    @dh1[:last_error][:error].class.should == ArgumentError
    @dh1[:blacklist_until].should == @now + @dh1[:blacklist_interval]

    @dh2[:last_error][:time].should_not == nil
    @dh2[:last_error][:method].should == :do_it
    @dh2[:last_error][:args].should == [ 1, 2 ]
    @dh2[:last_error][:error].class.should == ArgumentError
    @dh2[:blacklist_until].should == @now + @dh2[:blacklist_interval]

    @fd.available_delegates.should == [ @dh3 ]
    @fd.blacklisted_delegates.should == [ @dh1, @dh2 ]

    # Make d3 fail.
    @d3.err = TypeError

    lambda { @fd.do_it(1, 2).should == :d3 }.should raise_error(TypeError)

    @dh1[:last_error][:time].should_not == nil
    @dh1[:last_error][:method].should == :do_it
    @dh1[:last_error][:args].should == [ 1, 2 ]
    @dh1[:last_error][:error].class.should == ArgumentError

    @dh2[:last_error][:time].should_not == nil
    @dh2[:last_error][:method].should == :do_it
    @dh2[:last_error][:args].should == [ 1, 2 ]
    @dh2[:last_error][:error].class.should == ArgumentError

    @dh3[:last_error][:time].should_not == nil
    @dh3[:last_error][:method].should == :do_it
    @dh3[:last_error][:args].should == [ 1, 2 ]
    @dh3[:last_error][:error].class.should == TypeError
    @dh3[:blacklist_until].should == nil

    @fd.available_delegates.should == [ @dh3 ]
    @fd.blacklisted_delegates.should == [ @dh1, @dh2 ]

  end

end # describe
