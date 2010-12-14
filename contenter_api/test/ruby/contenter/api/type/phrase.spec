# -*- ruby -*-

# Test metadata:
# TEST_CONFIG_BEGIN
# enabled: true
# note: none
# owners: kurt
# tags: unit Contenter::Api Contenter::Api::Type::Phrase
# TEST_CONFIG_END

require 'contenter/api/store/contenter_yml'
require 'contenter/api/type/phrase'

require 'pp'

describe 'Contenter::Api::Type::Phrase' do 
  def store
    @store ||=
    Contenter::Api::Store::ContenterYml.
    new(:name => :contenter_yml, 
	:file => File.dirname(__FILE__) + '/../etc/contenter.yml'
	)
    end

  def api
    @api ||= 
      begin
        @api = Contenter::Api.new()
        Contenter::Api::Selector.default = {
          :country => :US,
          :language => :en,
          :application => :test,
        }
        @api.type(:phrase).store = store
        @api
      end
  end

  it 'should find content' do
    
    v = api.get(:phrase, :zip_code, :language => :en)
    v.to_s.should == 'ZIP Code'

    v = api.get(:phrase, :zip_code, :language => :es)
    v.to_s.should == "Código postal"
  end


end # describe

