require 'active_record_defer_constraints'

module DestroyControllerActions

  def destroy_prompt
    self.instance = model.find(params[:id])
    render :action => :destroy
  end

  def destroy
    self.instance = model.find(params[:id])
    if params[:confirm] && params[:commit] == 'Confirm' && params[:uuid] == self.instance.uuid
      self.instance.defer_constraints do
        self.instance.destroy
      end
      flash[:notice] = "#{model.name} #{self.instance.id} destroyed"
    else
      flash[:error] = "#{model.name} #{self.instance.id} destroy: NOT CONFIRMED"
    end
    redirect_to :action => :list
  rescue Exception => err
    flash[:error] = "Error occurred: #{err.inspect}"
    redirect_to :action => :show, :id => self.instance
  end

end # module
