
module CodeUiHelper
  def self.extend_object obj
    obj.instance_eval do
      default_order_options :order => "code"

      user_columns \
      :code, {
        :link_to => { :action => 'show' }
      },
      :name,
      :description
      
      show_columns \
      :code, {
        :link_to => { :action => 'edit' }
      },
      :name,
      :description,
      :created_at,
      :updated_at

      footer_partials :show => 'shared/related'
    end
  end
end

