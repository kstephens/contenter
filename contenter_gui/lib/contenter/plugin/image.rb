require 'contenter/plugin/null'

require 'contenter/content_converter'
require 'archive/zip'


module Contenter
  class Plugin
    # Default plugin for Image content.
    class Image < Null
      # Parses a ZIP file for images.
      def self.load_zip(opts = nil)
        file = 
          opts[:file] || 
          opts[:io].path || 
          (raise ArgumentError)
        api = Content::API.new

        api.load_begin do 
          Archive::Zip.open(file) do | zf |
            zf.each do | e |
              begin
                e_file_data = e.file_data
                # $stderr.puts "#{e.zip_path}"

                hash = { }
                hash[:content_type] = opts[:content_type]
                hash[:content_key] = File.basename(e.zip_path)

                hash[:language] = opts[:language]
                hash[:country] = opts[:country]
                hash[:brand] = opts[:brand]
                hash[:application] = opts[:application]

                hash[:filename] = e.zip_path
                hash[:data] = e_file_data.read 
                hash[:data_encoding] = nil

                hash[:mime_type] = 
                  Contenter::ContentConverter::Content.new(:data => hash[:data]).mime_type ||
                  opts[:mime_type] || 
                  UNDERSCORE
                
                api.load_content_from_hash hash
              ensure
                e_file_data.close rescue nil
              end
            end
          end
        end

        api
      end

      # Mixed into ContentTypesController.
      module ContentTypesControllerMixin
        def self.extend_object obj
          super
          # obj.prepend_view_path Contenter::CnuContenter.view_dir
        end

        def plugin_side_menus
          if self.instance
            [
             [ 'Upload', { :action => :upload, :id => self.instance } ],
            ]
          end
        end

        def plugin_upload
        end

        def plugin_upload_submit
          $stderr.puts "@upload = #{@upload.inspect}"

          @api = Image.load_zip(:io => @upload.upload, 
                                :filename => @upload.upload.original_filename, 
                                :content_type => @upload.content_type.to_s,
                                :brand => @upload.brand.to_s,
                                :country => @upload.country.to_s,
                                :language => @upload.language.to_s,
                                :application => @upload.application.to_s)
        end
      end # module

    end # class
  end # module
end # module

 
