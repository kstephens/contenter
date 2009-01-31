
=begin
class ActionView::Helpers::InstanceTag
  unless method_defined? :column_type_without_binary
    alias :column_type_without_binary :column_type
  end
  def column_type_with_binary
    type = column_type_without_binary
    type = :text if type == :binary
    type
  end
  alias :column_type :column_type_with_binary
end



# Streamlined sucks.
# There is no provision for making Addition columns editable
# Which basically forces a 1-to-1 mapping between database columns and UI elements.
# That basically prevents you from giving your users a better experence by abstracting
# the presentation from the data.  
# No real examples anywhere.
# So you are basically forced to do you own edit views for anything other than a rote CRUD
# edit view.
# Really fucking annoying.
class Streamlined::Column::Addition
  attr_accessor :enumeration, :check_box, :type
  def custom_column_value *args
    nil
  end

  # TODO: This method depends on item being in scope under the instance variable name
  #       :@#model_underscore. Yucky, but Rails' input method expects this. Revisit.
  def render_td_edit(view, item)
    if enumeration
      result = render_enumeration_select(view, item)
      $stderr.puts "  result #{__LINE__}"
    elsif check_box
      result = view.check_box(model_underscore, name, html_options)
      $stderr.puts "  result #{__LINE__}"
    else
      case type
      when :string
        result = view.text_field(model_undersore, name, :object => object)
      when :text, :binary
        result = view.textarea(model_undersore, name, :object => object)
      end
      result
    end
    $stderr.puts "  render_td_edit(#{view}, #{item.class}) => #{result.inspect}"
    append_help(result)
  end
  alias :render_td_new :render_td_edit

  def append_help(html)
    # html ||= '' # HACK!!!
    x = Builder::XmlMarkup.new
    x.div(:class => "streamlined_help") { x << help } unless help.blank?
    html << x.target!
  end
  
end
=end


module ContentAdditions
  def streamlined_name *args
    content_key.code
  end

  def data_short max_size = 16
    x = data || ''
    x =~ /\A[\n\r]*([^\n\r]*)[\n\r]/
    x = $1 || x
    if x != data || data.size > max_size
      # Handle UTF-8: do not truncate in the middle of a UTF-8 sequence.
      while max_size < data.size && (c = x[max_size]) && c > 127
        max_size += 1
      end

      x = x[0 .. max_size] + '...'
    end
    x
  end

  def data_formatted
    "<pre>#{ERB::Util.h data}</pre>"
  end

  def data_text_lines
    (x = data) ? x.count("\n") : 0
  end

  def data_text
    data
  end

  def data_text= x
    self.data = x
  end
end
Content.class_eval { include ContentAdditions }

Streamlined.ui_for(Content) do
  def self._list_field name, human_name = nil
    human_name ||= name.to_s.humanize
    {
      :human_name => human_name,
      :edit_in_list => false,
    }
  end

  def self._show_field name, human_name = nil
    human_name ||= name.to_s.humanize
    {
      :human_name => human_name,
      :show_view =>
      [ :link, 
        {
          :fields => [ :code ],
        }
      ],
    }
  end


  ####################################################################


  default_order_options :order => 
    [ :content_key, :language, :country, :brand, :application, :mime_type ].
    map { | x |
      x = x.to_s
      xs = x.pluralize
      "(SELECT #{xs}.code FROM #{xs} WHERE #{xs}.id = #{x}_id)"
    }.join(', ')

  ####################################################################


  list_columns \
  :content_key,  _list_field(:content_key, 'Key').
    update(:link_to => { 
               :controller => 'contents', 
               :action => 'show',
             }),
  :content_type_code, { 
    :human_name => 'Type',
  },
  :language,     _list_field(:language),
  :country,      _list_field(:country),
  :brand,        _list_field(:brand),
  :application,  _list_field(:application),
  :mime_type,    _list_field(:mime_type),
  :data_short, { 
    :human_name => 'Data',
    :link_to => { :action => 'show' },
  }
  
  show_columns \
  :uuid,
  :content_type_code, { 
    :human_name => 'Type',
  },
  :content_key,  _show_field(:content_key, 'Key'),
  :language,     _show_field(:language),
  :country,      _show_field(:country),
  :brand,        _show_field(:brand),
  :application,  _show_field(:application),
  :mime_type,    _show_field(:mime_type),
  :creator, {
    :show_view => 
    [
     :link, { 
       :controller => :users,
       :action => 'show',
     },
    ],
  },
  :created_at,
  :updater, {
    :show_view =>
    [
     :link, { 
       :controller => :users,
       :action => 'show',
     },
    ],
  },
  :updated_at,
  :version,
  :data_formatted, {
    :human_name => 'Data',
    :allow_html => true,
    # :link_to => { :action => 'edit' },
  }
  
  edit_columns \
  :content_key,
  :language,
  :country,
  :brand,
  :application,
  :mime_type,
  :data

end

