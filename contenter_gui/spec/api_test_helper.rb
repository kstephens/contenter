# -*- coding: utf-8 -*-
# -*- ruby -*-
#require 'test_helper'


module ApiTestHelper

  def load_stub_yaml
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
  - test
  - |-
    subject: Hello {{customer.email}}
    body: Your loan is ready.

END
    api = load_yaml yaml

  end
  def load_yaml yaml, opts = { }
    truncate_all unless opts[:truncate] == false

    api = Content::API.new
    api.load_from_yaml(yaml).should == api

    $stderr.puts api.result.to_yaml if opts[:verbose]

    if c = opts[:error_count]
      api.errors.size.should == c unless c == false 
    else
      unless api.errors.empty?
        $stderr.puts "API ERRORS:\n" + api.errors.map { | x | "#{x.inspect}\n  #{x[1].backtrace * "\n  "}" } * "\n\n"
      end
      api.errors.size.should == 0
    end

    if c = opts[:content_count]
      Content.count.should == c
      api.stats[:created].should == c if opts[:truncate] != false
    end
    if c = opts[:content_key_count]
      ContentKey.count.should == c
    end
    if c = opts[:expect_stats]
    end
    if u = opts[:user]
      # FIXME
    end

    api
  end

  # utility method to truncate all relevant tables in reverse-dependency order
  def truncate_all
    Content::Version.all.map(&:destroy)
    ContentKey::Version.all.map(&:destroy)
    Content.all.map(&:destroy)
    ContentKey.all.map(&:destroy)
  end
end # module


