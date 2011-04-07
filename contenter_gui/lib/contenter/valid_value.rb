require 'contenter'
require 'cgi' # CGI.escapeHTML

module Contenter
  # Helper to render value value interfaces.
  class ValidValue
    EMPTY_Array = [ ].freeze

    attr_accessor :name, :default, :valid_set, :ui, :display_name
    attr_accessor :value
    attr_accessor :ui_name, :ui_name_path, :ui_id, :ui_class
    attr_accessor :ui_cols, :ui_rows

    def self.many_from_hash vv
      result = { }
      if vv
        vv.each do | name, settings |
          obj = self.new
          obj.name = name
          obj.from_hash!(settings)
          result[obj.name] = obj
        end
      end
      result
    end

    def initialize hash = nil
      from_hash! hash if hash
    end

    def from_hash! hash
      self.name ||= hash[:name]

      self.ui ||= hash[:ui] || :textfield
      @ui_rows ||= hash[:ui_rows]
      @ui_cols ||= hash[:ui_cols]
      @ui_name ||= hash[:ui_name]
      @ui_name_path ||= hash[:ui_name_path]
      @ui_id ||= hash[:ui_id]
      @ui_class ||= hash[:ui_class]

      self.valid_set ||= hash[:valid_set]
      self.default ||= hash[:default] 

      case self.ui
      when :checkbox
        self.valid_set ||= [ 'f', 't' ]
      end

      self.default ||= (self.valid_set || EMPTY_Array).first

      self.display_name ||= hash[:display_name] || { }

      self
    end

    def value_or_default
      @value.nil? ? default : value
    end

    def valid?
      case ui
      when :checkbox
        val = to_bool(@value)
        val == false || val == true
      else
        case valid_set
        when nil
          true
        when Regexp
          self.valid_set.match(@value)
        when Array
          self.valid_set.include?(@value)
        else
          true
        end
      end
    end

    def ui_id
      @ui_id ||= "#{ui_name}".freeze
    end
    
    def ui_name_path
      @ui_name_path ||= '%s'.freeze
    end

    def ui_name
      @ui_name ||= "#{ui_name_path % name}".freeze
    end

    def ui_class
      @ui_class ||= "#{ui_id}".freeze
    end

    def ui_rows
      @ui_rows ||= 20
    end

    def ui_cols
      @ui_cols ||= 80
    end

    def html_show
      v = value_or_default
      case ui || :textfield
      when :textfield
        h(display_name[v] || v)
      when :textarea
        "<pre>#{h(display_name[v] || v)}</pre>"
      when :checkbox
        to_bool(v) ? "[X]" : "[ ]"
      when :dropdown, :select
        h(display_name[v] || v)
      else
        raise ArgumentError, "name = #{name.inspect} ui = #{ui.inspect}"
      end
    end

    def html_edit
      v = value_or_default
      case ui || :textfield
      when :textfield
        %Q{<input type="text" id="#{ui_id}" name="#{ui_name}" size="#{ui_cols}" value="#{h v}" />}
      when :textarea
        %Q{<textarea id="#{ui_id}" name="#{ui_name}" cols="#{ui_cols}" rows="#{ui_rows}">#{h v}</textarea>}
      when :checkbox
        %Q{<input type="checkbox" id="#{ui_id}" name="#{ui_name}" value="#{to_bool(v) ? 1 : nil}" />}
      when :dropdown, :select
        result = %Q{<select id="#{ui_id}" name="#{ui_name}">}
        valid_set.each do | vv |
          result << %Q{<option value="#{vv}" #{vv.to_s == v.to_s ? 'selected="selected"' : nil}>#{h(display_name[vv] || vv)}</option>}
        end
        result << %Q{</select>}
      else
        raise ArgumentError, "uname = #{name.inspect} ui = #{ui.inspect}"
      end
    end

    def html_escape value
      value = value.to_s
      CGI.escapeHTML(value)
    end
    alias :h :html_escape

    def to_bool value
      case value
      when nil, '', false
        false
      when Numeric
        ! value.zero?
      when String, Symbol
        case value.to_s
        when /\A[fn0]/i
          false
        else
          true
        end
      else
        true
      end
    end

  end # class
end # module
