# -*- ruby -*-

# Test metadata:
# TEST_CONFIG_BEGIN
# enabled: true
# note: none
# owners: kurt
# tags: unit Contenter::Api Contenter::Store::ContenterYml
# TEST_CONFIG_END

require 'contenter/api/store/contenter_uri'

require 'pp'

describe 'Contenter::Api::Store::ContenterUri' do 
  def store
    @@store ||= Contenter::Api::Store::ContenterUri.
      new({
	    :name => :contenter_uri, 
	    :base_uri => 'file://' + File.expand_path(File.dirname(__FILE__) + '/../etc' + '/file'),
          }
          )
  end

  it 'should read something' do
    s = store

    v = s.get(:phrase, :hello, Contenter::Api::Selector[nil, nil, nil, nil])
    # pp v
    v.data.should == "aksjdfl;aksjdlaksdjf"
    v.country.should == nil
    v.content_key.should == :hello
    v.content_type.should == :phrase
    v.content_status.should == :created

    v = s.get(:phrase, :no_love, Contenter::Api::Selector[nil, nil, nil, nil])
    # pp v
    v.should == nil

  end

  it 'should handle enumerations' do
    s = store
    v = s.enumerate_uri(:phrase, nil, Contenter::Api::Selector[nil, nil, nil, nil])
    v.should == "application=_&brand=_&columns=application%2Cbrand%2Ccontent_key%2Ccontent_type%2Ccountry%2Clanguage&content_type=phrase&country=_&language=_&unique=1"

    v = s.enumerate_uri(:phrase, nil, nil)
    v.should == "columns=application%2Cbrand%2Ccontent_key%2Ccontent_type%2Ccountry%2Clanguage&content_type=phrase&unique=1"

    v = s.enumerate(:phrase, nil, nil)
    v.size.should == 1
    v0 = v[0]
    v0[0].should == :hello
    v0[1].should == Contenter::Api::Selector[nil, nil, nil, nil]
  end

end # describe
