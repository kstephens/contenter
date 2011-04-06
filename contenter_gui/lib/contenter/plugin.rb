
module Contenter
  # A Contenter::Plugin provides for editing of compound data types stored in Content#data.
  # A new instance of a Contenter::Plugin subclass is created for each ContentType#plugin_instance.
  #
  # It provides:
  #  - templates for edit/show/new of content.
  #  - methods for converting posted compound params into Content#data (as yaml).
  #  - *Mixin modules that are attached to each Content, ContentKey, ContentType or controller instance,
  # as needed
  #
  # See Contenter::Plugin::Email and ContentsController for examples.
  class Plugin
    # General Plugin error.
    class Error < ::Exception
      class SubclassResponsibility < self; end

      # Factory error.
      class Factory < self; end

      # Template error.
      class Template < self; end

      class NotImplemented < self; end
    end

    # Verbosity.
    attr_accessor :verbose

    # The ContentType of this Plugin.
    attr_reader :content_type


    # This is mixed into the Content object.
    # Each subclass of Contenter::Plugin must define a module of the same name.
    module ContentMixin
      # Returns a String for "data" column in the contents/list view.
      def data_for_list
        data
      end
    end

    # The name of the default plugin class.
    DEFAULT_PLUGIN = '::Contenter::Plugin::Null'.freeze

    @@factory_cls_cache = { }
    # Returns a factory (class) for a plugin_name.
    def self.factory(plugin_name)
      plugin_name = DEFAULT_PLUGIN if plugin_name.blank?
      plugin_name = "::#{plugin_name}" unless plugin_name =~ /\A::/
      plugin_cls = (@@factory_cls_cache[plugin_name] ||= eval(plugin_name))
      plugin_cls
    rescue Exception => err
      raise Error::Factory, "Plugin.factory(#{plugin_name.inspect}): ERROR: #{err.inspect}\n  #{err.backtrace * "\n  "}"
    end

    MIXINS_IVAR = "@_contenter_plugin_mixins".freeze

    @@cls_const_get_cache = { }
    def cls_const_get cls, name
      c = @@cls_const_get_cache
      c = c[cls] ||= { }
      c = c[name] ||=
        [
         (cls.const_get(name) rescue nil)
        ]
      c.first
    end

    @@object_mixin_class_cache = { }

    # Computes the Mixin module name for obj.
    def object_mixin_class obj
      @@object_mixin_class_cache[obj.class] ||=
        case obj
        when Content, Content::Version
          'ContentMixin'
        when ContentKey, ContentKey::Version
          'ContentKeyMixin'
        when ContentsController, ContentVersionsController
          'ContentsControllerMixin'
          #      when ContentKeysController, ContentsKeysVersionController
          #        module_name ||= 'ContentKeysController'
        when ContentType, ActionController::Base
          obj.class.name + 'Mixin'
        end
    end

    # Mixin this Plugin's Mixins into an object.
    # Includes superclasses of this Plugin's class.
    # Content and ContentKey objects are observed by #content_event! method.
    def mix_into_object obj, module_name = nil
      if module_name
        module_name = "#{module_name}Mixin"
      else
        module_name = object_mixin_class(obj)
        raise ArgumentError, "module_name unspecified" unless module_name
      end

      # Don't mixin more than once.
      mixins = obj.extended_by

      if @verbose
        $stderr.puts " ### #{self.class}.mix_into_object(#{obj.class.name}, #{module_name})" if @verbose
        $stderr.puts "  ### #{self}: ancestors =\n#{self.class.ancestors.pretty_inspect}" if @verbose
      end

      (@self_class_ancestors ||= self.class.ancestors.freeze).reverse_each do | cls |
        mixin = cls_const_get(cls, module_name)
        # $stderr.puts "  *** #{obj} << #{mixin.inspect}" if mixin

        if mixin && ! mixins.include?(mixin)
          $stderr.puts "   ### #{self}: \#<#{obj.class.name} #{obj.object_id} #{obj.id || :NEW}>.extend(#{mixin})" if @verbose # || true
          obj.extend(mixin)
        end
        # $stderr.puts "  ### callers\n#{caller * "\n"}" if @verbose
      end

      # Start observing events on the object.
      case obj
      when Content, Content::Version, ContentKey, ContentKey::Version
        observe_content!(obj)
      end

      $stderr.puts "   ### #{self}: \#<#{obj.class.name} #{obj.object_id} #{obj.id || :NEW}>.extended_by =\n#{obj.extended_by.pretty_inspect}" if @verbose #

      self
    end


    # See ContentType#plugin_instance.
    def initialize opts = EMPTY_HASH
      @verbose = false
      @content_type = opts[:content_type]
      @template = { }
    end


    # Convert raw params[:content][:data] from controller to
    # Content#data Strings
    def params_to_data params
      raise Error::SubclassResponsibility, "params_to_data"
    end

    
    # Registers this plugin as an observer on all events on method #content_event!
    # e.g: (:before_validation, :after_validation, :before_save, :after_save, etc)
    # 
    def observe_content! obj
      obj.add_observer!(self, nil, [ :content_event! ])
    end

    # Callback per Content or ContentKey event.
    # Subclasses can override this method.
    def content_event! content, event
      # $stderr.puts "#{self.class.name}: content_event! #{content.id} #{event.inspect}"
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
      template_body = nil
      @template[name] ||=
        ERB.new(template_body = send(:"#{name}_erb"))
    rescue Exception => err
      raise Error::Template, "#{self.class}: template #{name.inspect}: ERROR #{err.inspect}: in\n#{template_body}\n#{err.backtrace * "\n"}"
    end
    private :template


    # Returns the HTML view ERB template for show.
    # Subclasses must override.
    def show_view_erb
      raise Error::SubclassResponsibility, "show_view_erb"
    end

    # Returns the HTML view ERB template for edit.
    # Subclasses must override.
    def edit_view_erb
      raise Error::SubclassResponsibility, "edit_view_erb"
    end

    # Returns the HTML view ERB template for new.
    # Subclasses may override.
    # Same as #edit_view_erb by default.
    def new_view_erb
      edit_view_erb
    end
  end
end
