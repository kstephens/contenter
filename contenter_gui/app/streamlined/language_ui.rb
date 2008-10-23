module LanguageAdditions
  def streamlined_name *args
    code
  end
end
Language.class_eval { include LanguageAdditions }

Streamlined.ui_for(Language) do
  extend CodeUiHelper
end   

