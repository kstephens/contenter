# -*- coding: utf-8 -*-
# -*- ruby -*-
#require 'test_helper'
require 'spec/spec_helper'
require 'spec/api_test_helper'

describe "Content::API" do
  include ApiTestHelper

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
  - cnuapp
  - |-
    subject: Hello {{customer.email}}
    body: Your loan is ready.

END
    api = load_yaml yaml, :content_count => 3, :content_key_count => 2
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
  - cnuapp
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

end

