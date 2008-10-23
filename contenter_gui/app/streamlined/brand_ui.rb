module BrandAdditions
  def streamlined_name *args
    code
  end
end
Brand.class_eval { include BrandAdditions }

Streamlined.ui_for(Brand) do
  extend CodeUiHelper
end
