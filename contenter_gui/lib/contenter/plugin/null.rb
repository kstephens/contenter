require 'contenter/plugin'

require 'ostruct'

module Contenter
  class Plugin
    # Default plugin for raw/unencoded content.
    class Null < self

      module ContentMixin
        def data_hash
          EMPTY_HASH
        end
      end

      def params_to_data params
        params
      end
      

      def show_view_erb
<<'END'
        <tr id="sl_field_content_data_formatted">

          <td class="sl_show_label">Data:</td>
          <td class="sl_show_value"><%= obj.data_formatted %></td>
        </tr>
END
      end
      
      def edit_view_erb
<<'END'
   <tr id="sl_field_content_data">
     <td class="sl_edit_label"><label for="content_data">Data</label></td>
     <td class="sl_edit_value">
<% case 
   when obj.is_image?
     unless obj.data.blank?
       flash[:content_data] = obj.data
 %>
   <%= obj.data_formatted  %>
   <% end %>
<% when obj.is_binary? %>
   <!-- NOTHING -->
<% else %>
     <textarea id="content_data" name="content[data]" cols="80" rows="<%= [ obj.data_text_lines, 20 ].max %>"
><%= h obj.data %></textarea>
<% end %>
</td></tr>
END
      end

    end # class Null
  end # class Plugin
end # module
