
# Support for common content class Crud Controllers.
module CrudController
  def index
    list
  end

  def related_options
     @related_options ||=
      begin
        # $stderr.puts "  controller = #{self.instance_variables.inspect}"
        var_name = params[:controller].singularize
        obj = self.instance_variable_get("@#{var_name}")
        hash = {
          :params => {
            :"#{var_name}_id" => obj.id,
          },
          :exact => true
        }
        # $stderr.puts "  #### \n  #{self.class} related_options = #{self.instance_variables.inspect} => #{hash.inspect}"
        hash
      end
  end
  # helper_method :related_options
end

