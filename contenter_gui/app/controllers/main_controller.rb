class MainController < ApplicationController
  def index
    redirect_to :controller => :search
  end
end
