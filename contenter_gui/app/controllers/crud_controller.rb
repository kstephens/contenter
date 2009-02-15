
# Support for common content class Crud Controllers.
module CrudController
  def index
    list
  end

  def edit_as_new
    self.crud_context = :new
    self.instance = model.find(params[:id])
    render_or_redirect(:success, 'new')
  end

  def related_options
    # $stderr.puts "  controller = #{self.instance_variables.inspect}"
    var_name = params[:controller].singularize
    obj = self.instance_variable_get("@#{var_name}")
    @related_options ||= {
      :params => {
        var_name.to_sym => 
        obj.code
      },
      :exact => true
    }
  end
end

