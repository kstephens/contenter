module ContentStatusAdditions
  def streamlined_name *args
    code
  end
end
ContentStatus.class_eval { include ContentStatusAdditions }

Streamlined.ui_for(ContentStatus) do
  extend CodeUiHelper
end

