# -*- coding: utf-8 -*-
# -*- ruby -*-

require 'spec/spec_helper'
require 'spec/api_test_helper'

describe 'VersionListName' do
  include ApiTestHelper

  before(:all) do 
    UserTracking.default_user = '__test__'

    # Put some data in there, damnit !
    yaml = <<'END'
--- 
:api_version: 1
:contents_columns: 
- :content_type
- :content_key
- :language
- :country
- :brand
- :application
- :data
:contents: 
- - phrase
  - new_loan
  - en
  - _
  - _
  - _
  - "new loan"
- - phrase
  - new_loan
  - es
  - _
  - _
  - _
  - "nuevo préstamo"
- - email
  - new_loan
  - en
  - _
  - _
  - cnuapp
  - |-
    subject: Hello {{customer.email}}
    body: Your loan is ready.

END
    api = load_yaml yaml

  end
 

  it 'Should be able to map from a Content or ContentKey back to a VersionListName' do
    now = Time.now
    name = "test_case_#{now.to_i}"

    vl = VersionList.create(:point_in_time => now, :comment => name)
    vl.content_versions.size.should == Content.count
    vl.content_key_versions.size.should == ContentKey.count

    vln = VersionListName.create(:name => name, :description => name, :version_list => vl)
    vl.content_versions.each do | cv |
      cv.version_list_names.should include(vln)
    end
    vl.content_key_versions.each do | ckv |
      ckv.version_list_names.should include(vln)
    end
  end # it


end # describe


