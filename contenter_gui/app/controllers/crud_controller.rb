
# Support for common content class Crud Controllers.
module CrudController
  def self.included target
    super
    target.before_filter :find_by_code, :only => [ :show, :edit ]
  end

  def index
    list
  end

  def find_by_code oid = nil
    oid ||= params[:id]

    obj = nil
    if model.column_names.include?("code")
      obj = model.find(:all, :conditions => { :code => oid }, :limit => 2)
      if obj = (obj.size == 1 && obj.first)
        params[:id] = obj.id
      end
    end
    
    self.instance = obj

    obj
  end

  def find_object oid = nil
    oid ||= params[:id]
    self.instance = find_by_code(oid) || model.find(oid)
    after_object_find!(self.instance)
    self.instance
  end

  # Hook used to mixin any controller plugins.
  def after_object_find! obj
    content_type = 
      case obj
      when ContentType
        obj
      when ContentKey, ContentKey::Version, Content, Content::Version
        obj.content_type
      when 
        nil
      end

    # $stderr.puts "  ### #{self.class} #{params[:action]}: after_object_find! content_type=#{content_type}"

    content_type.plugin_instance.mix_into_object(self) if content_type

    self
  end


  def check_capability! cap = nil
    cap ||= ''
    unless current_user.has_capability?(@capability_pattern = "controller/<<#{params[:controller]}>>/<<#{params[:action]}>>" + cap)
      raise Contenter::Error::Auth::NotAuthorized, @capability_pattern
=begin
      flash[:error] = "Not authorized for #{cap}"
      render :template => 'shared/unauthorized', :status => 401
      return false
=end
    end
    true
  end

  def check_capability_on_model_instance!
    if respond_to?(:plugin_check_capability_on_model_instance!)
      return false unless plugin_check_capability_on_model_instance!
    end
    check_capability!("?<<#{instance.class.name.underscore}>>=<<#{instance.code}>>")
  end

  def check_capability_on_content_type! content_type = nil
    content_type ||= (self.instance && self.instance.content_type)
    return true unless content_type
    if respond_to?(:plugin_check_capability_on_content_type!)
      return false unless plugin_check_capability_on_content_type!(content_type)
    end
    check_capability!("?<<content_type>>=<<#{content_type || '*'}>>")
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

