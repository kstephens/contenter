# -*- ruby -*-

# Test metadata:
# TEST_CONFIG_BEGIN
# enabled: true
# note: none
# owners: kurt
# tags: unit Contenter::Api Contenter::Api::Parse
# TEST_CONFIG_END

# Test environment:
require 'contenter/test/helper'

# Test target:
require 'contenter/api/parse'

# Test support:
# NONE

describe 'Contenter::Api::Parse' do
  include Contenter::Api::Parse

  def log(level, msg = nil)
    return
    msg ||= yield
    $stderr.puts "log: #{level}: #{msg}"
  end

  def get_data
    @get_data ||= 
      File.read(File.dirname(__FILE__) + '/etc/contenter.yml').freeze
  end

  def get_rows
    @rows ||=
      parse_yml_array(get_data, __FILE__)
  end


  it 'should parse an Array of Content objects.' do
    rows = get_rows
    # require 'pp'; pp rows

    rows.size.should == 3

    rows[0].content_type.should == :contract
    rows[0].content_key.should == :"ach_authorization"
    rows[0].mime_type.should == :'text/html'

    rows[1].content_type.should == :phrase
    rows[1].content_key.should == :"zip_code"
    rows[1].mime_type.should == nil
    rows[1].data.should == "ZIP Code"

    rows[2].content_type.should == :phrase
    rows[2].content_key.should == :"zip_code"
    rows[2].mime_type.should == nil
    rows[2].data.should == "Código postal"
  end

  it "should parse a Hash of [content_type][selector][content_key]." do
    hash = parse_yml_hash(get_rows, __FILE__)
    hash.keys.size == 2
    hash[:contract].keys.size.should == 1
    hash[:phrase].keys.size.should == 2
  end

  it "should not decode raw " do
    [ :raw, nil, :_, '_', '', false ].each do | enc |
      hash = { :data_encoding => enc, :data => 'raw' }
      decode_hash!(hash).should == false
      hash.keys.should == [ :data ]
      hash[:data].should == 'raw'
    end
  end

  it "should decode :base64 " do
    raw = ''
    (0..255).each { | i | raw << i.chr }
    [ :base64 ].each do | enc |
      hash = { :data_encoding => enc, :data => Base64.encode64(raw) }
      decode_hash!(hash).should == true
      hash.keys.should == [ :data ]
      hash[:data].should == raw
    end
  end

end # describe

