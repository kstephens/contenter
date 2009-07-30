
module CodeUiHelper
  def self.extend_object obj
    obj.instance_eval do
      extend UserTrackingUiHelper

      default_order_options :order => "code"

      uc = 
        [
         :code, {
           :link_to => { :action => 'show' }
         },
         :name,
         :description
        ]

      list_columns *uc


      case
      when obj.model == ContentType
        uc +=
          [
           :key_regexp,
           :plugin
          ]
      end

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
           :key_regexp,
           :plugin
          ]
      end

      sc += show_columns_user_tracking

      show_columns *sc

      footer_partials :show => 'shared/related'
    end
  end
end

