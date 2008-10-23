module ApplicationAdditions
  def streamlined_name *args
    code
  end
end
Application.class_eval { include ApplicationAdditions }

Streamlined.ui_for(Application) do
  extend CodeUiHelper
end

