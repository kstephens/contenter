module CountryAdditions
  def streamlined_name *args
    code
  end
end
Country.class_eval { include CountryAdditions }

Streamlined.ui_for(Country) do
  extend CodeUiHelper
end   
