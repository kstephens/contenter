
require 'contenter/yaml'

require 'yaml'

describe "Contenter::Yaml" do
  [ 
   nil,
   "",
   "  \t  ",
   "simple",
   "with whitespace",
   "  leading whitespace",
   "trailing whitespace   ",
   "  around whitespace  ",
   "\nleading newline",
   "trailing newline\n",
   "trailing newlines\n\n",
   "many trailing newlines\n\n",
   "\naround newline\n",
   "embedded\nnewline",
   "embedded\n  newline and whitespace",
   "embedded\n\nnewlines",
  ].each do | base |
    [ '', " ", "\t", "\n" ].each do | pre |
      [ '', "\n", "\n ", "\n\t" ].each do | post |
        str = base
        str = pre + str.to_s unless pre.empty?
        str = str.to_s + post unless post.empty?
        it "should handle string_as_yaml(#{str.inspect})." do
          yaml = <<"END"
:hash:
  :this: this
  :str: #{Contenter::Yaml.string_as_yaml(str, "    ")}
  :that: that
END
          # $stderr.puts "str = #{str.inspect}"
          # $stderr.puts "yaml = ----"; $stderr.write yaml
          hash = YAML::load(yaml)
          hash = hash[:hash]
          hash[:this].should == "this"
          hash[:that].should == "that"
          if hash[:str] != str
            $stderr.puts "str = #{str.inspect}"
            $stderr.puts "yaml = ----"; $stderr.write yaml
          end
          hash[:str].should == str
        end # it
      end # each
    end # each
  end # each
end # describe


