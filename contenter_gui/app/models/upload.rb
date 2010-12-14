# Represents a file upload.
class Upload < 
    Struct.new(
               :id,
               :content_type,
               :language_id,
               :country_id,
               :brand_id,
               :application_id,
               :comment,
               :upload,
               :file_type
               )
  def initialize opts = { }
    opts.each do | k, v |
      v = v.to_i if k == :id || k.to_s =~ /_id$/
      send("#{k}=", v)
    end
  end

  def application
    @application ||= 
      Application[application_id ||
            content_type.aux_data[:upload_default_application] ||
            content_type.aux_data[:default_application]
           ] ||
      (raise ArgumentError, "application not specified")
  end


  def brand
    @brand ||= 
      Brand[brand_id ||
            content_type.aux_data[:upload_default_brand] ||
            content_type.aux_data[:default_brand]
           ] ||
      (raise ArgumentError, "brand not specified")
  end

  def country
    @country ||= 
      Country[country_id ||
              brand.aux_data[:upload_default_country] ||
              brand.aux_data[:default_country]
             ]||
      (raise ArgumentError, "country not specified")
  end
  
  def language
    @language ||= 
      Language[language_id ||
               brand.aux_data[:upload_default_language] ||
               brand.aux_data[:default_language] ||
               country.aux_data[:upload_default_language] ||
               country.aux_data[:default_language]
              ] ||
      Language[:_]
  end
end

