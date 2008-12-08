module MimeTypeAdditions
  def streamlined_name *args
    code
  end
end
MimeType.class_eval { include MimeTypeAdditions }

Streamlined.ui_for(MimeType) do
  extend CodeUiHelper
end   
