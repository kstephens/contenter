# -*- ruby -*-
require 'spec/spec_helper'
require 'spec/api_test_helper'


describe WorkflowController, :type => :controller do
  controller_name 'workflow'

  include ApiTestHelper

  before(:all) do
    @root           = User['root']
    @content_editor = User['__content_editor__']
    @content_approver = User['__content_approver__']
    @content_releaser = User['__content_releaser__']

    UserTracking.current_user = '__test__'
    load_stub_yaml
    @content = ContentType[:phrase].contents.first

    # if you need to be logged in, your first line will be 
    # controller.stub!(:current_user).and_return(@root)
  end

  before(:each) do
    ActionMailer::Base.deliveries.clear
  end

  it 'should route workflow/perform_status_action/action to WorkflowController#perform_status_action with status_action' do
    params_from(:post, '/workflow/perform_status_action/approve').should == { 
      :controller    => 'workflow', 
      :action        => 'perform_status_action',
      :status_action => 'approve'
      }
  end

  it 'should recognize /workflow/list/approve as {:workflow/:list/:approve}' do
    opts = { :controller => 'workflow', :action => 'list', :status_action => 'approve' }
    assert_recognizes opts, '/workflow/list/approve'
  end

  it 'should recognize {:workflow/:list/:approve} } as /workflow/list/approve' do
    opts = { :controller => 'workflow', :action => 'list', :status_action => 'approve' }
    assert_routing '/workflow/list/approve', opts
  end

  it 'should not expose workflow/approve via HTTP GET' do
    get :perform_status_action, {:status_action => 'approve' }
    assert_response :method_not_allowed
  end

  it 'should fetch the content_ids from the request' do
    controller.stub!(:current_user).and_return(@root)
    post :perform_status_action, {:status_action => 'approve', :content_id => @content.id.to_s}
    @controller.instance_eval{self.content_ids}.should == [@content.id]
  end

=begin
  it 'should reject approvals by unauthorized users' do
    controller.stub!(:current_user).and_return(@content_editor)
    post :perform_status_action, {:status_action => 'approve', :content_id => @content.id.to_s}
    assert_response :unauthorized

    controller.stub!(:current_user).and_return(@content_approver)
    post :perform_status_action, {:status_action => 'approve', :content_id => @content.id.to_s}
    assert_response :redirect

    controller.stub!(:current_user).and_return(@content_releaser)
    post :perform_status_action, {:status_action => 'approve', :content_id => @content.id.to_s}
    assert_response :unauthorized
  end

  it 'should create nice routes from helpers' do
    controller.instance_eval{ status_action_path('approve') }.should == '/workflow/perform_status_action/approve'
  end

  it 'should create a version list when a content version is approved' do
    controller.stub!(:current_user).and_return(@content_approver)
    UserTracking.default_user = @content_approver.name
    UserTracking.current_user = @content_approver.name


    @content_approver.has_capability?('controller/<<workflow>>/<<perform_status_action>>/<<approve>>').should == true
    @content_approver.has_capability?("controller/<<workflow>>/<<perform_status_action>>/<<approve>>?<<content_type>>=<<*>>")
    @content_approver.has_capability?("controller/<<workflow>>/<<perform_status_action>>/<<approve>>?<<content_type>>=<<phrase>>")

    # precondition for approval
    c = Content.find(:first)
    c.set_content_status! ContentStatus[:modified]

    post :perform_status_action, {:status_action => 'approve', :content_id => "#{c.id}", 
      :version_list_comment => 'issue 55555', :version_list => {:issues => "2001"} } 

    approval_list = assigns[:approval_list]
    approval_list.should be_kind_of(VersionList)
    approval_list.id.should_not == nil

    approval_list.size.should == 1
    approval_list.comment.should include('issue 55555')

    response.should be_redirect # back to index page

    # Because we created a VersionList, and the observer is wired up to the after_save
    # event, we should have an email (see version_lists_controller_spec.rb:113)

    # TODO 
    ActionMailer::Base.deliveries.length.should > 0

  end
=end

  it 'should allow approved user to perform status action' do
    @root.has_capability?('controller/workflow/perform_status_action').should == true
    @content_approver.has_capability?('controller/workflow/perform_status_action').should == true
    @content_releaser.has_capability?('controller/workflow/perform_status_action').should == true
    @content_editor.has_capability?('controller/workflow/perform_status_action').should == false    

    @root.has_capability?('controller/workflow/perform_status_action/approve').should == true
    @content_approver.has_capability?('controller/workflow/perform_status_action/approve').should == true
    @content_releaser.has_capability?('controller/workflow/perform_status_action/approve').should == false
    @content_editor.has_capability?('controller/workflow/perform_status_action/approve').should == false    

    @root.has_capability?('controller/workflow/perform_status_action/release').should == true
    @content_approver.has_capability?('controller/workflow/perform_status_action/release').should == false
    @content_releaser.has_capability?('controller/workflow/perform_status_action/release').should == true
    @content_editor.has_capability?('controller/workflow/perform_status_action/release').should == false    
  end
  
end
