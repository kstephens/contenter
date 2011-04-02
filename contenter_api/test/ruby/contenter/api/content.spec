# -*- ruby -*-

# Test metadata:
# TEST_CONFIG_BEGIN
# enabled: true
# note: none
# owners: kurt
# should_run_with_rails_environment: false
# tags: unit Contenter::Api Contenter::Api::Content
# TEST_CONFIG_END

# Test environment:
require 'contenter/test/helper'

# Test target:
require 'contenter/api/content'
require 'contenter/api/selector'

# Test support:
# NONE

describe 'Contenter::Api::Content' do

  it 'should handle basic operations.' do
    sel = Contenter::Api::Selector.coerce(:language => :en, :country => :US, :brand => :brand)
    c = Contenter::Api::Content.new(:content_type => :type, :content_key => :key, :selector => sel, :data => '1234', :uuid => '12345-a234')

    c.data.should == '1234'
    c.selector.should == sel
    c.language.should == sel.language

    h = c.to_hash
    h.keys.sort_by{|k| k.to_s}.should == [:application, :brand, :content_key, :content_key_uuid, :content_status, :content_type, :country, :creator, :data, :filename, :language, :md5sum, :mime_type, :updater, :uuid, :version]
    c.to_hash.should == {:application=>nil, :updater=>nil, :content_key=>:key, :version=>nil, :country=>:US, :content_key_uuid=>nil, :content_status=>nil, :data=>"1234", :brand=>:brand, :creator=>nil, :filename=>nil, :uuid=>"12345-a234", :md5sum=>nil, :language=>:en, :mime_type=>nil, :content_type=>:type}

    c.cannonical_uri_query_params.should == "application=_&brand=brand&content_key=key&content_type=type&country=US&language=en"

    c.cannonical_uri.should == "http://localhost:3000/contents/show/12345-a234"

    span_tag = "<span class=\"contenter_cms_link\" title=\"cms: key\" href=\"http://localhost:3000/contents/show/12345-a234\">" + "[C]" + "</span>"

    c.html_href('').should == span_tag

    c.html_href('Something').should == "#{span_tag}Something"

    c2 = Contenter::Api::Content.new(c.to_hash.merge(:version => 12))

    c2.cannonical_uri.should == "http://localhost:3000/contents/show/12345-a234?version=12"

    c2.cannonical_uri_query_params(:content_status => 'approved|released').
      should == "application=_&brand=brand&content_key=key&content_status=approved%7Creleased&content_type=type&country=US&language=en"
    
    span_tag = "<span class=\"contenter_cms_link\" title=\"cms: key\" href=\"http://localhost:3000/contents/show/12345-a234?version=12\">" + "[C]" + "</span>"

    c2.html_href('').should == span_tag 

    c2.html_href('Something').should == "#{span_tag}Something"

    c2.html_href('Something <br/>').should == "#{span_tag}Something <br/>"

    c2.html_href('Go to <a href="this_page">click another here</a> other <a href="link">link</a>').
      should == "#{span_tag}Go to <a href=\"this_page\">click another here</a> other <a href=\"link\">link</a>"
  end

  it 'should generate cannonical_uri_query_params' do
    c3 = Contenter::Api::Content.new(:content_type => :phrase, :content_key => :"hello", :language => :_, :country => :_, :branch => :_, :application => :_, :mime_type => :_)
    c3.cannonical_uri_query_params.
      should == "application=_&brand=_&content_key=hello&content_type=phrase&country=_&language=_"
  end

end # describe

