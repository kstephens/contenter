class MainController < ApplicationController
  def index
    redirect_to :controller => :contents
  end
end
