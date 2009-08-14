# -*- ruby -*-
#require 'test_helper'
require 'spec/spec_helper'

require 'yaml' # YAML::load

describe "Contenter::Plugin::Email" do

  it 'round-trips data Hash as YAML with single-line :body with leading-whitespace' do
    plugin = Contenter::Plugin::Email.new({ })
    hash = { 
      :sender  => "true sender",
      :subject => "false You've got \"plugins\" in da house!",
      :body => '  one line, no newlines',
    }
    YAML.load(result = plugin.params_to_data(hash)).should == hash
    # $stderr.puts "\n" + result
    result.should == (<<END)
---
:sender: "true sender"
:subject: "false You've got \\"plugins\\" in da house!"
:body: "  one line, no newlines"
END
  end

  it 'round-trips data Hash as YAML with single-line :body with trailing newline' do
    plugin = Contenter::Plugin::Email.new({ })
    hash = { 
      :sender  => "true sender",
      :subject => "false You've got \"plugins\" in da house!",
      :body => "one line, trailing newlines\n", 
    }
    YAML.load(result = plugin.params_to_data(hash)).should == hash
    # $stderr.puts "\n" + result
    result.should == (<<END) + '  '
---
:sender: "true sender"
:subject: "false You've got \\"plugins\\" in da house!"
:body: |+
  one line, trailing newlines
END
# 'emacs
  end

  it 'round-trip data Hash as YAML with multi-line :body' do
    plugin = Contenter::Plugin::Email.new({ })
    hash = { 
      :sender  => "true sender",
      :subject => "false You've got \"plugins\" in da house!",
      :body => <<"END"
  Multi
line
  stuff with backslashes
\\n
,
  leanding whitespace
'n stuff
END
# 'emacs
    }
    # $stderr.puts("====\n" + plugin.params_to_data(hash))
    YAML.load(result = plugin.params_to_data(hash)).should == hash
    # $stderr.puts "\n" + result
    result.should == (<<END)
---
:sender: "true sender"
:subject: "false You've got \\"plugins\\" in da house!"
:body: "  Multi\\nline\\n  stuff with backslashes\\n\\\\n\\n,\\n  leanding whitespace\\n'n stuff\\n"
END
  end

end # describe
