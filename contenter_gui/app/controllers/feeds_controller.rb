class FeedsController < ApplicationController
  def index
    rss
  end

  def rss
    @contents = Content.find(:all, :conditions => [ "updated_at > NOW() - (interval '1 day')" ], :order => "updated_at DESC", :limit => 100)
    headers['Content-Type'] = 'application/rss+xml'
    render :layout => false, :template => 'feeds/rss.rxml' # , :content_type => 'application/xml'
=begin
    respond_to do | format |
      format.html
      format.xml { render :xml => @contents }
    end
=end
  end

end # class

