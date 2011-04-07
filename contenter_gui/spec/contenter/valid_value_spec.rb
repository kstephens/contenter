# -*- ruby -*-
#require 'test_helper'
require 'spec/spec_helper'

require 'contenter/valid_value' 

describe "Contenter::ValueValue" do
  attr_accessor :vv

  def create h = nil
    self.vv = Contenter::ValidValue.new(h)
    self.vv
  end

  it 'handles :ui => :checkbox' do
    create(:name => :my_checkbox, 
           :ui => :checkbox,
           :value => nil
           )
    vv.value = 'foo'
    vv.valid?.should == true
    vv.html_show.should == '[ ]'
    vv.html_edit.should == "<input type=\"checkbox\" id=\"my_checkbox\" name=\"my_checkbox\" value=\"\" />"

    vv.value = true
    vv.valid?.should == true
    vv.html_show.should == '[X]'
    vv.html_edit.should == "<input type=\"checkbox\" id=\"my_checkbox\" name=\"my_checkbox\" value=\"1\" />"

  end

  it 'handles :ui => :textfield' do
    create(:name => :my_textfield, 
           :ui => :textfield,
           :valid_set => [ 'foo & bar', 'baz' ]
           )
    vv.value = 'foo & bar'
    vv.valid?.should == true
    vv.html_show.should == 'foo &amp; bar'
    vv.html_edit.should == "<input type=\"text\" id=\"my_textfield\" name=\"my_textfield\" size=\"80\" value=\"foo &amp; bar\" />"

    vv.value = 'baz'
    vv.valid?.should == true
    vv.html_show.should == 'baz'
    vv.html_edit.should == "<input type=\"text\" id=\"my_textfield\" name=\"my_textfield\" size=\"80\" value=\"baz\" />"

    vv.value = 'booze'
    vv.valid?.should == false
    vv.html_show.should == 'booze'
    vv.html_edit.should == "<input type=\"text\" id=\"my_textfield\" name=\"my_textfield\" size=\"80\" value=\"booze\" />"

  end

  it 'handles :ui => :textarea' do
    create(:name => :my_textarea,
           :ui_name_path => 'content[data][%s]',
           :ui_id => 'ta123',
           :ui => :textarea,
           :ui_rows => 4
           )
    vv.value = 'foo & bar'
    vv.valid?.should == true
    vv.html_show.should == '<pre>foo &amp; bar</pre>'
    vv.html_edit.should == "<textarea id=\"ta123\" name=\"content[data][my_textarea]\" cols=\"80\" rows=\"4\">foo &amp; bar</textarea>"

  end

end # describe
