
# Support for common content class Crud Controllers.
module CrudController
  def self.included target
    super
    target.before_filter :find_by_code, :only => [ :show, :edit, :update ]
  end

  def index
    list
  end

  def find_by_code oid = nil
    oid ||= params[:id]

    if model.column_names.include?("code")
      obj = model.find(:all, :conditions => { :code => oid }, :limit => 2)
      if obj = obj.size == 1 && obj.first
        params[:id] = obj.id
      end
    end
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

