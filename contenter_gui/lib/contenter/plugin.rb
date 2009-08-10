
module Contenter
  # A Contenter::Plugin provides for editing of compound data types stored in Content#data
  # It provides:
  #  - templates for edit/show/new of content
  #  - methods for converting posted compound params into Content#data (as yaml)
  # See Contenter::Plugin::Email and ContentsController.
  class Plugin
    # General Plugin error.
    class Error < ::Exception; end

    # This is mixed into the Content object.
    # Each subclass must define a module of the same name.
    module ContentMixin
      # Returns a String for "data" column in the contents/list view.
      def data_for_list
        data
      end
    end

    
    def mix_into_object object
      self.class.ancestors.reverse.each do | cls |
        mixin = cls.const_get('ContentMixin') rescue nil
        # $stderr.puts "  *** #{object} << #{mixin.inspect}" if mixin
        object.extend(mixin) if mixin
      end
      self
    end


    # The ContentType of this Plugin.
    attr_reader :content_type


    # See ContentType#plugin_instance.
    def initialize opts
      @content_type = opts[:content_type]
      @template = { }
    end


    # Takes raw params[:content][:data] from controller and converts it to
    # Content#data Strings
    def params_to_data params
      raise Error, "subclass responsiblity"
    end


    # Renders the show_view with the binding given.
    def show_view b
      template(:show_view).result(b)
    end

    # Renders the edit_view with the binding given.
    def edit_view b
      template(:edit_view).result(b)
    end

    # Renders the new_view with the binding given.
    def new_view b
      template(:new_view).result(b)
    end


    # Returns the cached ERB object by calling #{name}_erb.
    def template name
      @template[name] ||=
        ERB.new(send(:"#{name}_erb"))
    end
    private :template


    # Returns the HTML view for show.
    # Subclasses must override.
    def show_view_erb
      raise Error, "subclass responsiblity"
    end

    # Returns the HTML view for edit.
    # Subclasses must override.
    def edit_view_erb
      raise Error, "subclass responsiblity"
    end

    # Returns the HTML view for new.
    # Subclasses may override.
    # Same as edit_view_erb by default.
    def new_view_erb
      edit_view_erb
    end
  end
end
