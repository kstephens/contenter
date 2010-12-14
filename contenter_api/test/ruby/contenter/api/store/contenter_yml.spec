# Test metadata:
# TEST_CONFIG_BEGIN
# enabled: true
# note: none
# owners: kurt
# tags: unit Contenter::Api Contenter::Store::ContenterYml
# TEST_CONFIG_END

require 'contenter/api/store/contenter_yml'

require 'pp'

describe 'Contenter::Api::Store::ContenterYml' do 
  it 'should read something' do
    s = Contenter::Api::Store::ContenterYml.
    new(:name => :contenter_yml, 
	:file => File.dirname(__FILE__) + '/../etc/contenter.yml'
	)
    hash = s.hash
    hash.should_not == nil

    # pp hash

    hash.keys.sort { | a, b | a.to_s <=> b.to_s }.
    should == [ :contract, :phrase ]

    v = hash[:phrase]
    v.keys.sort { | a, b | a.to_s <=> b.to_s }.
    should == [ :"Contenter::Api::Selector[:test, nil, nil, :en]", :"Contenter::Api::Selector[:test, nil, nil, :es]" ]

    hash[:contract].keys.sort { | a, b | a.to_s <=> b.to_s }.
    should == [ :"Contenter::Api::Selector[:test, nil, :US, :en]" ]

    v = s.get(:phrase, :zip_code, :'Contenter::Api::Selector[:test, nil, nil, :en]')
    v.data.should == 'ZIP Code'

    v = s.get(:phrase, :zip_code, :'Contenter::Api::Selector[:test, nil, nil, :es]')
    v.data.should == "Código postal"

    v = s.get(:contract, :ach_authorization, :'Contenter::Api::Selector[:test, nil, :US, :en]')
    v.data.should == "<%\n  num_agreement = 3 \n%>\nsomething <%= num_agreement >\n"

  end

  it 'should successively overlay additional files passed' do 
    s = Contenter::Api::Store::ContenterYml.
    new(:name => :contenter_yml, 
	:file => [File.dirname(__FILE__) + '/../etc/contenter.yml', File.dirname(__FILE__) + '/../etc/contenter-overlay.yml']
	)
    hash = s.hash
    hash.should_not == nil

    hash.keys.sort { | a, b | a.to_s <=> b.to_s }.
    should == [ :contract, :phrase ]

    v = hash[:phrase]
    v.keys.sort { | a, b | a.to_s <=> b.to_s }.
    should == [ :"Contenter::Api::Selector[:test, nil, nil, :en]", :"Contenter::Api::Selector[:test, nil, nil, :es]" ]

    hash[:contract].keys.sort { | a, b | a.to_s <=> b.to_s }.
    should == [ :"Contenter::Api::Selector[:test, nil, :US, :en]" ]

    v = s.get(:phrase, :zip_code, :'Contenter::Api::Selector[:test, nil, nil, :en]')
    v.data.should == 'ZIP Code'

    v = s.get(:phrase, :zip_code, :'Contenter::Api::Selector[:test, nil, nil, :es]')
    v.data.should == "Código postal"

    v = s.get(:phrase, :zip_code_2, :'Contenter::Api::Selector[:test, nil, nil, :en]')
    v.data.should == 'ZIP Code_2'

    v = s.get(:contract, :ach_authorization, :'Contenter::Api::Selector[:test, nil, :US, :en]')
    v.data.should == 'OVERLAY'
    
  end
end
