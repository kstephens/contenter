require 'spec/spec_helper'

describe SessionsController, :type => :controller do

  integrate_views

  it 'should be able to request the login page without error' do
    get :new
    #$stderr.puts puts response.body
    response.should be_success
  end

end
