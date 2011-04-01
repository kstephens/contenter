
module CodeUiHelper
  def self.extend_object obj
    obj.instance_eval do
      extend UserTrackingUiHelper

      # $stderr.puts "   obj.model = #{obj.model.name} #{obj.model.instance_methods.sort.inspect}"

      has_aux_data = obj.model.instance_methods.include?('aux_data_yaml')

      default_order_options :order => "code"

      lc = 
        [
         :code, {
           :link_to => { :action => 'show' }
         },
         :name,
         :description,
        ]

      uc = lc.dup

      case
      when obj.model == ContentType
        lc +=
          [
           :mime_type, _list_field(:mime_type),
           :content_key_count,
           :content_count,
          ]
      when obj.model == MimeType
        lc +=
          [
           :mime_type_super, _list_field(:mime_type_super),
          ]
      end
      list_columns *lc

      case
      when obj.model == ContentType
        uc +=
          [
           :mime_type,
           :key_regexp,
           :plugin
          ]
      when obj.model == MimeType
        uc +=
          [
           :mime_type_super,
          ]
      end

      if has_aux_data
        uc +=
          [
           :aux_data_yaml, { :read_only => false, :pre => true },
          ]
      end

      # debugger if obj.model == MimeType && has_aux_data
      edit_columns *uc

      ###################################

      sc = 
        [
         :code, {
           :link_to => { :action => 'edit' }
         },
         :name,
         :description,
        ]
      # $stderr.puts "  #{self}: obj = #{obj.model.inspect}"

      case
      when obj.model == ContentType
        sc +=
          [
           :mime_type, _show_field(:mime_type),
           :key_regexp,
           :plugin,
           :content_key_count,
           :content_count,
          ]
      when obj.model == MimeType
        sc +=
          [
           :mime_type_super, _show_field(:mime_type_super),
          ]
      end

      if has_aux_data
        sc +=
          [
           :aux_data_yaml, { :read_only => false, :pre => true }, # , _show_field(:aux_data_yaml),
          ]
        # debugger if obj.model == MimeType
      end

      sc += show_columns_user_tracking

      show_columns *sc

      footer_partials :show => 'shared/related'

      # debugger if has_aux_data
      1
    end
  end
end

