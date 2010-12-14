# -*- ruby -*-

# Test target.
require 'cabar/sort'


describe Cabar::Sort do
  include Cabar::Sort

  before do
=begin

Sort the graph nodes (@unsorted) such that all keys in
@children are listed before all values listed as dependents:

a ----> c -
 \         \
  ----> d ---> x ---> y ---> z ---> 1
                  /            \
b ----------------              --> 2

=end
    @srand ||= srand($$ ^ Time.now.to_i)

    @children = {
      'a' => [ 'c', 'd' ],
      'b' => [ 'y' ],
      'c' => [ 'x' ],
      'd' => [ 'x' ],
      'x' => [ 'y' ],
      'y' => [ 'z' ],
      'z' => [ '1', '2' ],
    }
    @children_proc = lambda { | x | @children[x] || [ ] } 
    @unsorted = (@children.keys + @children.values).flatten.uniq
    # Correct answers are:
    @sorted = 
      [ 
       # eg: 'c' and 'd' are mutually independent, but 'a' depends on both.
       [ 'a', 'b', 'c', 'd', 'x', 'y', 'z', '1', '2' ],
       [ 'a', 'b', 'd', 'c', 'x', 'y', 'z', '1', '2' ],
       [ 'a', 'b', 'c', 'd', 'x', 'y', 'z', '2', '1' ], 
       [ 'a', 'b', 'd', 'c', 'x', 'y', 'z', '2', '1' ], 
       [ 'b', 'a', 'c', 'd', 'x', 'y', 'z', '1', '2' ],
       [ 'b', 'a', 'd', 'c', 'x', 'y', 'z', '1', '2' ],
       [ 'b', 'a', 'c', 'd', 'x', 'y', 'z', '2', '1' ], 
       [ 'b', 'a', 'd', 'c', 'x', 'y', 'z', '2', '1' ], 
       ]
  end

  def check_immediate_dependencies! input, result
    a = ai = b = bi = nil
    result.each_with_index do | a, ai |
      @children_proc.call(a).each do | b |
        bi = result.index(b)
        next unless bi
        bi.should_not == nil
        ai.should < bi
      end
    end
  rescue Exception => err
    $stderr.puts "FAILED: "
    $stderr.puts "  input = #{input.inspect}"
    $stderr.puts "  result = #{result.inspect}"
    $stderr.puts "  #{a.inspect}@#{ai.inspect} ->"
    $stderr.puts "    #{b.inspect}@#{bi.inspect}"
    raise err
  end

  
  it "sorts specific cases correctly" do
    [ 
     ["2", "d", "c", "z", "a", "y", "x", "1", "b"],
     ["x", "2", "b", "z", "c", "1", "d", "a", "y"],
    ].each do | permutation |
      result = topographic_sort(permutation, 
                                {
                                  :dependents => @children_proc, 
                                  # :debug => true,
                                }
                                )
      check_immediate_dependencies! permutation, result
    end
  end # it


  it "sorts random permutations topologically." do
    1000.times do
      permutation = @unsorted.sort { | a, b | rand(10000) <=> rand(10000) }
      result = topographic_sort(permutation, :dependents => @children_proc)

      check_immediate_dependencies! permutation, result

      correct = @sorted.any? { | x | result === x } == true
=begin
      puts "permutation = #{permutation.inspect}"
      puts "  result    = #{result.inspect}"
      puts "  correct   = #{correct.inspect}"
      exit(1) unless correct
=end
      correct.should == true
    end 
  end # it

  it "sorts random subset permutations topologically." do
    1000.times do
      unsorted = @unsorted.select { | n | rand(2) == 0 }
      sorted = @sorted.map { | x | x.select { | n | unsorted.include? n } }.uniq

      permutation = unsorted.sort { | a, b | rand(10000) <=> rand(10000) }
      result = topographic_sort_subset(permutation, @unsorted, :dependents => @children_proc)

      check_immediate_dependencies! permutation, result

      correct = sorted.any? { | x | result === x } == true
=begin
      puts "permutation = #{permutation.inspect}"
      puts "sorted      = \n  #{sorted.map{|x| x.inspect}.join(",\n  ")}"
      puts "  result    = #{result.inspect}"
      puts "  correct   = #{correct.inspect}"
#      exit(1) unless correct
=end
      correct.should == true
    end 
  end # it

  it "sorts permutations with :order option." do
    # With :order.
    sorted = 
      [ 
       @sorted[0]
      ]
    
    1000.times do
      permutation = @unsorted.sort { | a, b | rand(10000) <=> rand(10000) }
      result = topographic_sort(permutation, 
                                :dependents => @children_proc, 
                                :order => lambda { | a, b | a <=> b })
      #puts "permutation = #{permutation.inspect}"
      #puts "  result    = #{result.inspect}"
      check_immediate_dependencies! permutation, result
      @sorted.any? { | x | result === x }.should == true
    end
  end # it

  it "handles cyclical graphs." do
    @children['z'] << 'x'
    @sorted << ["a", "b", "c", "d", "2", "1", "x", "y", "z"]
    @sorted << ["a", "b", "d", "c", "y", "z", "2", "x", "1"]
    @sorted << ["a", "b", "d", "c", "z", "x", "1", "2", "y"]
    @sorted << ["a", "b", "c", "d", "2", "x", "1", "y", "z"]
    @sorted << ["a", "b", "c", "d", "y", "z", "2", "x", "1"]
    @sorted << ["a", "b", "d", "c", "1", "x", "2", "y", "z"]
    @sorted << ["a", "b", "d", "c", "z", "1", "2", "x", "y"]
    @sorted << ["a", "b", "c", "d", "y", "z", "2", "1", "x"]
    @sorted << ["a", "b", "c", "d", "x", "1", "2", "y", "z"]
    @sorted << ["a", "b", "c", "d", "1", "x", "2", "y", "z"]
    @sorted << ["a", "b", "c", "d", "z", "2", "x", "1", "y"]
    @sorted << ["a", "b", "d", "c", "2", "x", "1", "y", "z"]
    @sorted << ["a", "b", "c", "d", "y", "z", "x", "1", "2"]
    @sorted << ["a", "b", "c", "d", "x", "2", "1", "y", "z"]
    @sorted << ["a", "b", "d", "c", "x", "1", "2", "y", "z"]
    @sorted << ["a", "b", "d", "c", "y", "z", "x", "2", "1"]
    @sorted << ["a", "b", "c", "d", "1", "2", "x", "y", "z"]
    @sorted << ["a", "b", "c", "d", "z", "1", "2", "x", "y"]
    @sorted << ["a", "b", "c", "d", "y", "z", "1", "2", "x"]

    1000.times do
      permutation = @unsorted.sort { | a, b | rand(10000) <=> rand(10000) }
      result = topographic_sort(permutation, 
                                :dependents => @children_proc,
                                :order => lambda { | a, b | a <=> b })

      correct = @sorted.any? { | x | result === x } == true
=begin
      puts "permutation = #{permutation.inspect}"
      puts "  result    = #{result.inspect}"
      puts "  correct   = #{correct.inspect}"
      exit(1) unless correct
=end
      correct.should == true

    end 
  end

end # describe

