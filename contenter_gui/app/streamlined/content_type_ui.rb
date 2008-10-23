module ContentTypeAdditions
  def streamlined_name *args
    code
  end
end
ContentType.class_eval { include ContentTypeAdditions }

Streamlined.ui_for(ContentType) do
  extend CodeUiHelper
end   
