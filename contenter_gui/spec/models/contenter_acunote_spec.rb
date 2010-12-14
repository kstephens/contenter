require 'spec/spec_helper'

describe 'Contenter Acunote Config' do

  # troubleshooting tasks rely on being able to override this in non-web processes
  it 'should remain unfrozen and alterable' do
    ContenterAcunote.config.should_not be_frozen
    ContenterAcunote.config['to'] = 'XXX'
    ContenterAcunote.config['to'].should == 'XXX'
  end

end
