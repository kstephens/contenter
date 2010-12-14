module ContentTypeAdditions
  def streamlined_name *args
    code
  end
  def content_key_count
    content_keys.count
  end
  def content_count
    contents.count
  end
end
ContentType.class_eval { include ContentTypeAdditions }

Streamlined.ui_for(ContentType) do
  extend CodeUiHelper
end   
