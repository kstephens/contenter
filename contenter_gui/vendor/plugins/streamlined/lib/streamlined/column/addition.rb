class Streamlined::Column::Addition < Streamlined::Column::Base
  attr_accessor :name, :sort_column

  def initialize(sym, parent_model)
    @name = sym.to_s
    @human_name = sym.to_s.humanize
    @read_only = true
    @parent_model = parent_model
  end
  
  def addition?
    true
  end

  # Array#== calls this
  def ==(o)
    return true if o.object_id == object_id
    return false unless self.class === o
    return name.eql?(o.name)
  end
  
  def sort_column
    @sort_column.blank? ? name : @sort_column
  end
  
  def render_td_show(view, item)
    render_content(view, item)
  end

  def render_td_edit(view, item)
=begin
    custom_value = custom_column_value(view, model_underscore, name)   
    options = custom_value ? html_options.merge(:value => custom_value) : html_options
=end
    options = html_options
    value = item.send(self.name)
    options = options.merge(:value => value)
    if pre
      result = view.text_area(model_underscore, name, options)
    else
      result = view.input(model_underscore, name, options)
    end
    result
  end
end
