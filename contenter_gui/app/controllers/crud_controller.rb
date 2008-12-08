module CrudController
  def index
    list
  end

  def related_params
    # $stderr.puts "  controller = #{self.instance_variables.inspect}"
    var_name = params[:controller].singularize
    obj = self.instance_variable_get("@#{var_name}")
    @related_params ||= {
      var_name.to_sym => 
      obj.code
    }
  end
end

