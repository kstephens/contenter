# -*- ruby -*-
require 'test_helper'

describe "Content::API" do

  def get_yaml
  end


  def load_yaml
yaml = <<'END'
--- 
:api_version: 1
:contents_columns: 
- :uuid
- :content_key
- :content_type
- :language
- :country
- :brand
- :application
- :data
:contents: 
- - ~
  - add
  - phrase
  - en
  - _
  - _
  - _
  - add
- - ""
  - foobar
  - phrase
  - en
  - US
  - US
  - _
  - |
    <b>first line</b>
    <i>second line</i>

- - 9301c481-bc3c-4edc-8ce0-8dd66c097473
  - hello
  - phrase
  - en
  - _
  - _
  - _
  - hello
- - ~
  - hello_world
  - phrase
  - _
  - _
  - _
  - _
  - |
    <{{t :hello}}>, <{{t :world}}>

- - ""
  - new_loan
  - email
  - en
  - _
  - _
  - cnuapp
  - |-
    subject: Hello {{{customer.email}}
    body: Your loan is ready.
- - ""
  - world
  - phrase
  - en
  - _
  - _
  - _
  - world
- - ""
  - hello
  - phrase
  - es
  - _
  - _
  - _
  - hola
- - ""
  - world
  - phrase
  - es
  - _
  - _
  - _
  - mundo
- - ~
  - foobar
  - phrase
  - _
  - _
  - _
  - test
  - foobar
END
    api = Content::API.new
    api.load_from_yaml(yaml).should == api
    puts api.result.to_yaml
    api
  end


  it 'should use given uuids' do
    api = load_yaml
  end

end

