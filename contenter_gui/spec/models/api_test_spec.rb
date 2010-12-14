# -*- coding: utf-8 -*-
# -*- ruby -*-
#require 'test_helper'
require 'spec/spec_helper'
require 'spec/api_test_helper'

describe "Content::API" do
  include ApiTestHelper

  before(:each) do 
    UserTracking.current_user = '__test__'
    UserTracking.default_user = '__test__'
    # $stderr.puts "UserTracking.default_user = #{UserTracking.default_user.inspect}"
    # $stderr.puts "UserTracking.current_user = #{UserTracking.current_user.inspect}"
    UserTracking.default_user.should_not == nil
    UserTracking.default_user.id.should == User['__test__'].id

    UserTracking.current_user.should_not == nil
    UserTracking.current_user.id.should == User['__test__'].id
  end

  def make_content key, data
yaml = <<"END"
--- 
:api_version: 1
:contents_columns: 
- :content_type
- :content_key
- :language
- :country
- :brand
- :application
- :data
:contents: 
- - :phrase
  - #{key.inspect}
  - en
  - _
  - :_
  - :_
  - #{data.inspect}
END
    # $stderr.puts "make_content yaml = \n#{yaml}"
    api = load_yaml yaml
    
    ck = ContentKey.find(:first, :conditions => { :content_type_id => ContentType[:phrase], :code => key })
    c = Content.find(:first, :conditions => { :content_key_id => ck })
    c.should_not == nil

    c
  end

  include Contenter::Api::Parse
  def log(*args)
  end

  def get_yaml
  end

  it 'should distingush keys by content_type' do
yaml = <<'END'
--- 
:api_version: 1
:contents_columns: 
- :content_type
- :content_key
- :language
- :country
- :brand
- :application
- :data
:contents: 
- - phrase
  - new_loan
  - en
  - _
  - _
  - _
  - "new loan"
- - phrase
  - new_loan
  - es
  - _
  - _
  - _
  - "nuevo préstamo"
- - email
  - new_loan
  - en
  - _
  - _
  - test
  - |-
    subject: Hello {{customer.email}}
    body: Your loan is ready.

END
    api = load_yaml yaml, :content_count => 3, :content_key_count => 2, :user => '__test__'
    keys = ContentKey.find(:all)
    keys = keys.inject({ }) { | h, o | (h[o.code] ||= [ ]) << o; h }
    keys['new_loan'].size.should == 2
  end


  it 'should create Content and ContentKeys' do
yaml = <<'END'
--- 
:api_version: 1
:contents_columns: 
- :uuid
- :content_type
- :content_key
- :language
- :country
- :brand
- :application
- :data
:contents: 
- - ~
  - phrase
  - add
  - en
  - _
  - _
  - _
  - add
- - ""
  - phrase
  - foobar
  - en
  - US
  - US
  - _
  - |
    <b>first line</b>
    <i>second line</i>

- - 9301c481-bc3c-4edc-8ce0-8dd66c097473
  - phrase
  - hello
  - en
  - _
  - _
  - _
  - hello
- - ~
  - phrase
  - hello_world
  - _
  - _
  - _
  - _
  - |
    <{{t :hello}}>, <{{t :world}}>

- - ""
  - phrase
  - new_loan
  - en
  - _
  - _
  - _
  - "new loan"
- - ""
  - phrase
  - new_loan
  - es
  - _
  - _
  - _
  - "nuevo préstamo"
- - ""
  - email
  - new_loan
  - en
  - _
  - _
  - test
  - |-
    subject: Hello {{customer.email}}
    body: Your loan is ready.
- - ""
  - phrase
  - world
  - en
  - _
  - _
  - _
  - world
- - ""
  - phrase
  - hello
  - es
  - _
  - _
  - _
  - hola
- - ""
  - phrase
  - world
  - es
  - _
  - _
  - _
  - mundo
- - ~
  - phrase
  - foobar
  - _
  - _
  - _
  - test
  - foobar
END
    api = load_yaml yaml, :content_count => 11, :content_key_count => 7
    keys = ContentKey.find(:all)
    keys = keys.inject({ }) { | h, o | (h[o.code] ||= [ ]) << o; h }
    keys.values.
      flatten.
      map { | x | x.code }.
      sort.should ==
      [
       "add",
       "foobar",
       "hello",
       "hello_world", 
       "new_loan",
       "new_loan",
       "world",
      ]
    contents = Content.find(:all)
  end


  it 'should handle version conflicts' do
    key = "#{__FILE__}:#{__LINE__}"
    c = make_content(key, 'add')
    
yaml = <<"END"
--- 
:api_version: 1
:contents_columns: 
- :uuid
- :content_type
- :content_key
- :version
- :language
- :country
- :brand
- :application
- :data
:contents: 
# id #{c.id}
- - #{c.uuid.inspect}
  - :#{c.content_type.code.inspect}
  - #{c.content_key.code.inspect}
  - #{c.version + 2}
  - :#{c.language.code.inspect}
  - :#{c.country.code.inspect}
  - :#{c.brand.code.inspect}
  - :#{c.application.code.inspect}
  - #{(c.data + " CHANGED at #{__FILE__}:#{__LINE__}").inspect}
END
    # $stderr.puts yaml
    api = load_yaml yaml, :truncate => false, :error_count => 1
    api.errors[0][0].class.should == Hash
    api.errors[0][1].class.should == Contenter::Error::VersionConflict
    api.stats[:version_conflicts].should == 1

    # Content is unchanged.
    cx = Content.find(c.id)
    cx.data.should == c.data
    cx.version.should == c.version
    cx.versions.size.should == c.versions.size
  end

  it 'should handle recognize a non-conflicting version' do
    key = "#{__FILE__}:#{__LINE__}"
    c = make_content(key, 'add')

    new_data = nil
yaml = <<"END"
--- 
:api_version: 1
:contents_columns: 
- :uuid
- :content_type
- :content_key
- :version
- :language
- :country
- :brand
- :application
- :data
:contents: 
# id #{c.id}
- - #{c.uuid.inspect}
  - :#{c.content_type.code.inspect}
  - #{c.content_key.code.inspect}
  - #{c.version}
  - :#{c.language.code.inspect}
  - :#{c.country.code.inspect}
  - :#{c.brand.code.inspect}
  - :#{c.application.code.inspect}
  - #{(new_data = (c.data + " CHANGED at #{__FILE__}:#{__LINE__}")).inspect}
END
    # $stderr.puts yaml
    api = load_yaml yaml, :truncate => false
    api.stats[:version_conflicts].should == 0

    # Content is changed.
    cx = Content.find(c.id)
    cx.data.should_not == c.data
    cx.data.should == new_data
    cx.version.should_not == c.version
    cx.versions.last.data.should_not == c.data
    cx.versions.last.data.should == new_data
  end



  it 'should handle round-trip a binary image.' do
    ck = ContentKey.create!(:code => "test #{__FILE__}:#{__LINE__}", 
                            :content_type => ContentType[:image],
                            :name => '', :description => ''
                           )

    filename = File.dirname(__FILE__) + "/../../public/images/streamlined/add_16.png"
    c = Content.create!(:content_key => ck,
                        :language => Language[:_],
                        :country => Country[:_],
                        :brand => Brand[:_],
                        :application => Application[:_],
                        :mime_type => MimeType[:'image/png'],
                        :filename => filename,
                        :data => File.read(filename)
                       )

    yaml = Content::API.new(:params => { :id => c.id }).dump

    content = parse_yml_array(yaml, __FILE__)
    content.size.should == 1

    content[0].content_key.should == c.content_key.to_s.to_sym
    content[0].content_type.should == c.content_type.to_s.to_sym
    content[0].filename.should == c.filename
    content[0].data.should == c.data
    content[0].md5sum.should == c.md5sum
    content[0].mime_type.to_sym.should == c.mime_type.code.to_sym
  end

end

