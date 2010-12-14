# -*- ruby -*-


# Test target:
require 'cabar/environment'

# Test Dependencies:
require 'yaml'


describe Cabar::Environment do
  def create 
    e = Cabar::Environment.new('CABAR_FOO' => 'foo', 'CABAR_BAR' => nil)
    e['CABAR_FOO'].should == 'foo'

    e['CABAR_BAR'].should == nil
    e['CABAR_BAZ'] = 'baz'

    e['CABAR_BAZ'].should == 'baz'
    e['CABAR_NA'].should == nil
    e
  end

  it "should handle basic operations" do
    e = create
  end # it

  it "should handle read-only operations" do
    e = create
    e.read_only?('CABAR_BAZ').should == false
    e.read_only?('CABAR_NA').should == false
    e.read_only!('CABAR_BAZ').should == e
    e.read_only?('CABAR_BAZ').should == true
    lambda { e['CABAR_BAZ'] = 'kajsdflkjsd' }.should raise_error(::ArgumentError)

    e.read_only!('CABAR_NA')
    lambda { e['CABAR_NA'] = 'alskjfalksdjf' }.should raise_error(::ArgumentError)
  end # it

  it "should modify an environment Hash during #with" do
    e = create
    e['CABAR_BAZ'] = 'new_baz'

    dst = {
      'CABAR_FOO' => 'old_foo',
      'CABAR_BAR' => 'old_bar',
    }
    dst_save = dst.dup

    # $stderr.puts "dst = #{dst.inspect}"
    e.with(dst) do # | dst_arg |
      # dst_arg.object_id.should == dst.object_id
      # $stderr.puts "dst = #{dst.inspect}"
      dst.keys.sort.should == [ 'CABAR_BAZ', 'CABAR_FOO' ]
      dst['CABAR_FOO'].should == 'foo'
      dst['CABAR_BAR'].should == nil
      dst['CABAR_BAZ'].should == 'new_baz'
    end

    # ensure dst is restored.
    # $stderr.puts "dst = #{dst.inspect}"
    dst.should == dst_save
  end


  it "should handle a configuration-style Hash" do
    ENV['CABAR_BAR'] = 'BAR_INHERITED'
    config = YAML::load <<'END'
CABAR_FOO:
  value: FOO
CABAR_BAR:
  inherit: true
CABAR_BAZ:
  value: BAZ_LOCKED
  locked: true
CABAR_L:
  locked: true
END
    # require 'pp'; pp config
    e = Cabar::Environment.new(config)
    e.keys.sort.should == [ 'CABAR_BAR', 'CABAR_BAZ', 'CABAR_FOO' ]

    e['CABAR_FOO'].should == 'FOO'

    e['CABAR_BAR'].should == 'BAR_INHERITED'
    e['CABAR_BAR'] = 'BAR_FORCED'
    e['CABAR_BAR'].should == 'BAR_INHERITED'    

    e['CABAR_BAZ'].should == 'BAZ_LOCKED'
    e['CABAR_BAZ'] = 'BAZ_FORCED'
    e['CABAR_BAZ'].should == 'BAZ_LOCKED'

    e['CABAR_L'].should == nil
    e['CABAR_L'] = 'L'
    e['CABAR_L'].should == nil
  end

end # describe

