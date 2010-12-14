require 'contenter/plugin'

require 'ostruct'

module Contenter
  class Plugin
    # Default plugin for raw/unencoded content.
    class Email < self
      # This is mixed into the Content object.
      module ContentMixin
        def data_hash
          @data_hash ||=
            data ? YAML.load(data) : { }
        end

        def data_changed!
          @data_hash = nil
        end

        def data_for_list
          data_hash[:subject]
        end
      end

      def params_to_data params
        # Ensure keys are Symbols in the YAML.
        params = params.inject({ }){ | h, (k, v) | h[k.to_sym] = v; h }
        s = "---
:sender: #{params[:sender].inspect}
:subject: #{params[:subject].inspect}
:body: #{Contenter::Yaml.string_as_yaml(params[:body], '  ')}
"
        s
      end

      
      def show_view_erb
      end

      def edit_view_erb
<<'END'
   <tr id="sl_field_content_data_sender">
     <td class="sl_edit_label"><label for="content_data_sender">Sender</label></td>
     <td class="sl_edit_value"><input type="text" id="content_data_sender" name="content[data][sender]" width="80" value="<%= obj.data_hash[:sender] %>" /></td></tr>

   <tr id="sl_field_content_data_subject">
     <td class="sl_edit_label"><label for="content_data_subject">Subject</label></td>
     <td class="sl_edit_value"><input type="text" id="content_data_subject" name="content[data][subject]" width="80" value="<%= obj.data_hash[:subject] %>"
/></td></tr>

   <tr id="sl_field_content_data_body">
     <td class="sl_edit_label"><label for="content_data_body">Body</label></td>
     <td class="sl_edit_value"><textarea id="content_data_body" name="content[data][body]" cols="80" rows="<%= 20 %>"
><%= h obj.data_hash[:body] %></textarea></td></tr>

END
      end

 
    end # class Email
  end # class Plugin
end # module

