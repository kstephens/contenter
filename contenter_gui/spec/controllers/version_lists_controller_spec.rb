require 'spec/spec_helper'
require 'spec/api_test_helper'


describe VersionListsController do
=begin
  include ApiTestHelper
  controller_name 'version_lists'

  integrate_views # forces view errors to fail a test

  before(:each) do
    UserTracking.current_user = '__test__'
    load_stub_yaml
    # override in individual tests if needed to test lower-permission functions
    controller.stub!(:current_user).and_return(User['root'])
  end

  describe 'Closing the session version list' do
    before(:each) do
      ActionMailer::Base.deliveries.clear
    end

    it 'should save a comment upon closing' do
      vl = VersionList.first
      vl.add_content(ContentVersion.first) if vl.empty?

      # post :action, params_hash, session_data_hash
      post :close, {:id => vl.id,
                    :version_list_comment => 'COMMENTFOO', 
                    :version_list => {:issues => '1234'} }, 
                   {:version_list_id => vl.id }

      vl.reload.comment.should include('COMMENTFOO')

      session[:version_list_id].should be_nil # its been nuked

      ActionMailer::Base.deliveries.length.should >= 1

      response.should be_redirect # back to index
    end
  end
=end

end
