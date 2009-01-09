
module CodeUiHelper
  def self.extend_object obj
    obj.instance_eval do
      default_order_options :order => "code"

      uc = 
        [
         :code, {
           :link_to => { :action => 'show' }
         },
         :name,
         :description
        ]

      case
      when obj.model == ContentType
        uc +=
          [
           :key_regexp,
          ]
      end

      user_columns *uc


      ###################################

      sc = 
        [
         :code, {
           :link_to => { :action => 'edit' }
         },
         :name,
         :description,
        ]
      $stderr.puts "  #{self}: obj = #{obj.model.inspect}"

      case
      when obj.model == ContentType
        sc +=
          [
           :key_regexp,
          ]
      end

      sc +=
        [ 
         :created_at,
         :updated_at
        ]
      show_columns *sc

      footer_partials :show => 'shared/related'
    end
  end
end

