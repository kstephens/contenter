
require 'contenter/hash'

require 'yaml'

describe "contenter/hash.rb" do
  it "should add Hash#project." do 
    h = { :a => 1, :b => 2, :c => 3 }
    h.project.should == { }
    h.project(:a).should == { :a => 1 }
    h.project(:b).should == { :b => 2 }
    h.project(:x).should == { :x => nil }
    h.project(:a, :c).should == { :a => 1, :c => 3 }
    h.project([]).should == { }
    h.project([:a, :x]).should == { :a => 1, :x => nil }
  end

  describe "Hash::OrderedKey" do
    it "should order keys." do
      h = { :a => 1, :b => 2, :c => 3, 10 => 7, 2 => 6, 1 => 4, 1.2 => 5, "a" => 8 }
      h_keys = h.keys.dup
      # require 'pp'; pp h_keys
      h.extend(Hash::OrderedKey)
      h.keys.should == [1, 1.2, 2, 10, :a, "a", :b, :c] if h_keys != h.keys
      YAML::dump(h).should == "--- \n1: 4\n1.2: 5\n2: 6\n10: 7\n:a: 1\na: 8\n:b: 2\n:c: 3\n"
    end
  end
end

