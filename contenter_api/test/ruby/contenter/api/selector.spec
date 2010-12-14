# -*- ruby -*-

# Test metadata:
# TEST_CONFIG_BEGIN
# enabled: true
# note: none
# owners: kurt
# tags: unit Contenter::Api Contenter::Api::Selector spec_server
# TEST_CONFIG_END

# Test environment:
require 'contenter/test/helper'

# Test target:
require 'contenter/api/selector'

# Test support:
Contenter::Api::Selector.configure!


describe 'Contenter::Api::Selector' do
  # Handy alias
  Selector = Contenter::Api::Selector

  def setup
    @default_save = Selector.default

    Selector.default = {
      :application => :test,
      :brand => :test,
      :country => :US,
      :language => :en,
    }
  end

  before(:each) do
    setup
  end

  after(:each) do
    Selector.default = @default_save
  end


  it 'should coerce equal Selectors to the same object' do
    x = { :country => :US, :language => :en }
    y = { :country => :US, :language => :en }
    
    xo = Selector.coerce(x)
    yo = Selector.coerce(y)

    xo.object_id.should == yo.object_id

    xo = Selector.coerce(xo)
    yo = Selector.coerce(yo)

    xo.object_id.should == yo.object_id
  end

  it 'should handle empty overlays of current Selector' do 
    Selector.with do
      Selector.current.object_id.should == Selector.default.object_id
    end
  end

  it 'should handle overlays of current Selector' do 
    Selector.with(:brand => :JOE) do
      Selector.current.object_id.should_not == Selector.default.object_id
      Selector.current.brand.should == :JOE
      Selector.current.language.should == Selector.default.language
      Selector.current.country.should == Selector.default.country
      Selector.current.application.should == Selector.default.application
    end
  end

  it 'should handle nested overlays of current Selector' do 
    Selector.with(:brand => :JOE) do
      joe = Selector.current
      Selector.with(:brand => :test, :language => :es) do 
        Selector.current.object_id.should_not == Selector.default.object_id
        Selector.current.object_id.should_not == joe.object_id
        Selector.current.brand.should == :test
        Selector.current.language.should == :es
        Selector.current.country.should == Selector.default.country
        Selector.current.application.should == Selector.default.application
      end
      Selector.current.object_id.should_not == Selector.default.object_id
      Selector.current.brand.should == :JOE
      Selector.current.language.should == Selector.default.language
      Selector.current.country.should == Selector.default.country
      Selector.current.application.should == Selector.default.application
    end
  end

  it 'should return cached enumerations depending on the dynamic current Selector' do
  begin
    current_save = Selector.current

    xo = Selector.coerce(:country => :US, :language => :en )
    Selector.current = nil
    xoe = xo.enumerate
    xoe.object_id.should == xo.enumerate.object_id
    xoe.frozen?.should == true

    Selector.current = { :brand => :OTHER }
    xo = Selector.coerce(:language => :es)
    xoe = xo.enumerate
    xoe.object_id.should == xo.enumerate.object_id
    xoe.frozen?.should == true
  ensure
    Selector.current = current_save
  end
  end

  it 'should return #uri_params with :_ for nil values.' do
    require 'pp'

    xo = Selector.coerce(:country => :US, :language => :en )
    xo.uri_params.should == { :country => :US, :language => :en, :brand => :_, :application => :_ }
    xo.uri_params.object_id.should == xo.uri_params.object_id
    xo.uri_params.frozen?.should == true
  end

  it 'should return different enumerations depending on the dynamic current Selector' do
  begin
    current_save = Selector.current

    require 'pp'

    xo = Selector.coerce(:country => :US, :language => :en )
    Selector.current = nil
    xoe = xo.enumerate
    # pp xoe
    xoe.should == [
                   Contenter::Api::Selector[:test, :test, :US, :en],
                   Contenter::Api::Selector[nil, :test, :US, :en],
                   Contenter::Api::Selector[:test, nil, :US, :en],
                   Contenter::Api::Selector[nil, nil, :US, :en],
                   Contenter::Api::Selector[:test, :test, nil, :en],
                   Contenter::Api::Selector[nil, :test, nil, :en],
                   Contenter::Api::Selector[:test, nil, nil, :en],
                   Contenter::Api::Selector[nil, nil, nil, :en],
                   Contenter::Api::Selector[:test, :test, :US, nil],
                   Contenter::Api::Selector[nil, :test, :US, nil],
                   Contenter::Api::Selector[:test, nil, :US, nil],
                   Contenter::Api::Selector[nil, nil, :US, nil],
                   Contenter::Api::Selector[:test, :test, nil, nil],
                   Contenter::Api::Selector[nil, :test, nil, nil],
                   Contenter::Api::Selector[:test, nil, nil, nil],
                   Contenter::Api::Selector[nil, nil, nil, nil]]
   
    Selector.current = { :brand => :OTHER }
    xo = Selector.coerce(:language => :es)
    xoe = xo.enumerate
    # pp xoe
    xoe.should == [
                   Contenter::Api::Selector[:test, :OTHER, :US, :es],
                   Contenter::Api::Selector[nil, :OTHER, :US, :es],
                   Contenter::Api::Selector[:test, :test, :US, :es],
                   Contenter::Api::Selector[nil, :test, :US, :es],
                   Contenter::Api::Selector[:test, nil, :US, :es],
                   Contenter::Api::Selector[nil, nil, :US, :es],
                   Contenter::Api::Selector[:test, :OTHER, nil, :es],
                   Contenter::Api::Selector[nil, :OTHER, nil, :es],
                   Contenter::Api::Selector[:test, :test, nil, :es],
                   Contenter::Api::Selector[nil, :test, nil, :es],
                   Contenter::Api::Selector[:test, nil, nil, :es],
                   Contenter::Api::Selector[nil, nil, nil, :es],
                   Contenter::Api::Selector[:test, :OTHER, :US, :en],
                   Contenter::Api::Selector[nil, :OTHER, :US, :en],
                   Contenter::Api::Selector[:test, :test, :US, :en],
                   Contenter::Api::Selector[nil, :test, :US, :en],
                   Contenter::Api::Selector[:test, nil, :US, :en],
                   Contenter::Api::Selector[nil, nil, :US, :en],
                   Contenter::Api::Selector[:test, :OTHER, nil, :en],
                   Contenter::Api::Selector[nil, :OTHER, nil, :en],
                   Contenter::Api::Selector[:test, :test, nil, :en],
                   Contenter::Api::Selector[nil, :test, nil, :en],
                   Contenter::Api::Selector[:test, nil, nil, :en],
                   Contenter::Api::Selector[nil, nil, nil, :en],
                   Contenter::Api::Selector[:test, :OTHER, :US, nil],
                   Contenter::Api::Selector[nil, :OTHER, :US, nil],
                   Contenter::Api::Selector[:test, :test, :US, nil],
                   Contenter::Api::Selector[nil, :test, :US, nil],
                   Contenter::Api::Selector[:test, nil, :US, nil],
                   Contenter::Api::Selector[nil, nil, :US, nil],
                   Contenter::Api::Selector[:test, :OTHER, nil, nil],
                   Contenter::Api::Selector[nil, :OTHER, nil, nil],
                   Contenter::Api::Selector[:test, :test, nil, nil],
                   Contenter::Api::Selector[nil, :test, nil, nil],
                   Contenter::Api::Selector[:test, nil, nil, nil],
                   Contenter::Api::Selector[nil, nil, nil, nil]]
  ensure
    Selector.current = current_save
  end
  end

end # describe

