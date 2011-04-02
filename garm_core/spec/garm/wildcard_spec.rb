require 'contenter/wildcard'

describe "Contenter::Wildcard" do
  include Contenter::Wildcard

  it "should handle non-wildcards" do
    str = ""
    split_wildcard(str).should == [ [ "", nil ] ]
    enumerate_wildcard(str).should == [ "" ]

    str = "no wild"
    split_wildcard(str).should == [ [ "no wild", nil ] ]
    enumerate_wildcard(str).should == [ "no wild" ]
  end

  it "should handle a single wildcard" do
    str = "prefix <<wild>> suffix"
    split_wildcard(str).should == [ [ "prefix ", "wild" ], [ " suffix", nil ] ]
    enumerate_wildcard(str).should ==
      [
       "prefix * suffix",
       "prefix wild suffix",
       "prefix + suffix",
      ]
  end

  it "should handle a single empty wildcard" do
    str = "prefix <<>> suffix"
    split_wildcard(str).should == [ [ "prefix ", "" ], [ " suffix", nil ] ]
    enumerate_wildcard(str).should ==
      [
       "prefix * suffix",
       "prefix  suffix",
       "prefix + suffix",
      ]
  end

  it "should handle multiple wildcards" do
    str = "controller/<<c>>/<<a>>?query=<<thing>>"
    split_wildcard(str).should == 
      [ [ "controller/", "c" ], [ "/", 'a' ], [ "?query=", 'thing' ] ]
    enumerate_wildcard(str).should ==
      ["controller/*/*?query=*", "controller/*/*?query=thing", "controller/*/*?query=+", "controller/*/a?query=*", "controller/*/a?query=thing", "controller/*/a?query=+", "controller/*/+?query=*", "controller/*/+?query=thing", "controller/*/+?query=+", "controller/c/*?query=*", "controller/c/*?query=thing", "controller/c/*?query=+", "controller/c/a?query=*", "controller/c/a?query=thing", "controller/c/a?query=+", "controller/c/+?query=*", "controller/c/+?query=thing", "controller/c/+?query=+", "controller/+/*?query=*", "controller/+/*?query=thing", "controller/+/*?query=+", "controller/+/a?query=*", "controller/+/a?query=thing", "controller/+/a?query=+", "controller/+/+?query=*", "controller/+/+?query=thing", "controller/+/+?query=+"]
  end


  it "should handle brace_expansion" do
    brace_expansion(nil).should == 
      [ ]

    brace_expansion('').should == 
      [ '' ]

    brace_expansion("hello,world").should == 
      [ "hello,world" ]

    brace_expansion("{hello,world}").should ==
      [ "hello", "world" ]

    brace_expansion("pre {hello,world}").should ==
      [ "pre hello", "pre world" ]

    brace_expansion("{hello,world} post").should ==
      [ "hello post", "world post" ]

    brace_expansion("pre {hello,world} post").should ==
      [ "pre hello post", "pre world post" ]

    brace_expansion("pre {hello,world} post {1,2,3}").should ==
      ["pre hello post 1", "pre hello post 2", "pre hello post 3", "pre world post 1", "pre world post 2", "pre world post 3"]

=begin
    # NOT SUPPORTED: try
    # bash -c 'echo {1,foo{2,3},4}{5,6}'
    brace_expansion("{1,foo{2,3},4}{5,6}").should ==
      [ '15', '16', 'foo25', 'foo26', 'foo35', 'foo36', '45', '46' ]
=end

  end

=begin
  it "should not expand magic wildcards" do
    str = "controller/<<*>>/<<a>>?query=<<+>>"
    split_wildcard(str).should == 
      [ [ "controller/*", nil ], [ "/", 'a' ], [ "?query=+", nil ] ]
    enumerate_wildcard(str).should ==
      ["controller/*/*?query=+", "controller/*/a?query=+", "controller/*/+?query=+"]
  end
=end

end # describe
