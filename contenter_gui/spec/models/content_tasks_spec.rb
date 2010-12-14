require 'spec/spec_helper'
require 'spec/api_test_helper'

describe "Content with task ids" do
  include ApiTestHelper

  before(:all) do 
    UserTracking.default_user = '__test__'
    UserTracking.current_user = '__test__'

    load_stub_yaml
  end

  it "should save empty strings instead of nulls for the tasks column" do
    # content loaded via yaml files that never specified tasks
    c = Content.find(:first)
    c.tasks.should == ""

    c = Content.create(:content_key => ContentKey.first,
                       :language => Language[:_],
                       :country => Country[:_],
                       :brand => Brand[:_],
                       :application => Application[:_],
                       :mime_type => MimeType[:_],
                       :data => 'new'
                       )
    c.save!
    c.reload.tasks.should == ""
  end

  it 'should store taskids as space delimited' do
    c = Content.first
    c.tasks = "123; 456"
    c.save!

    # we surround with spaces so 123 does not match 12345
    c.tasks.should == " 123 456 " 
  end

  it 'should require task ids' do
    # Use of stubbing makes this override local to this test, to avoid the caching
    # behavior of config(file)
    c = Content.first
    c.tasks = ""

    # invoked by controllers when configured to do so in issue_notifier.yml
    c.normalize_tasks!
    c.validate_tasks_is_not_empty!

    c.errors.should_not be_empty
  end
end
