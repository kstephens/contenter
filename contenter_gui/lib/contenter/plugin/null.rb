require 'contenter/plugin'

require 'ostruct'

module Contenter
  class Plugin
    # Default plugin for raw/unencoded content.
    class Null < self
      # This is mixed into the Content object.
      module ContentMixin
      end
    end

    def params_to_data params
      params
    end


    def show_view_erb
    end

    def edit_view_erb
<<'END'
   <tr id="sl_field_content_data">
     <td class="sl_edit_label"><label for="content_data">Data</label></td>
     <td class="sl_edit_value"><textarea id="content_data" name="content[data]" cols="80" rows="<%= [ obj.data_text_lines, 20 ].max %>"
><%= h obj.data %></textarea></td></tr>
END
    end

  end
end
