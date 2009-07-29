# -*- coding: utf-8 -*-
# -*- ruby -*-
#require 'test_helper'


module ApiTestHelper

  def load_yaml yaml, opts = { }
    if opts[:truncate] != false
      ContentKey.find(:all).each{ | x | x.destroy }
      Content.find(:all).each { | x | x.destroy }
    end

    api = Content::API.new
    api.load_from_yaml(yaml).should == api

    puts api.result.to_yaml

    unless api.errors.empty?
      $stderr.puts api.errors.map { | x | "#{x.inspect}\n  #{x[1].backtrace * "\n  "}" } * "\n\n"
    end

    api.errors.size.should == 0

    if c = opts[:content_count]
      Content.count.should == c
      api.stats[:created].should == c if opts[:truncate] != false
    end
    if c = opts[:content_key_count]
      ContentKey.count.should == c
    end
    if c = opts[:expect_stats]
    end

    api
  end

end # module


