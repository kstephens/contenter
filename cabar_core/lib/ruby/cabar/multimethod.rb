module Cabar
  # Mixin to define methods that dispatch on the type of the first argument.
  # See Multimethod::ClassMethods#multimethod.
  module Multimethod
    def self.included target
      super
      target.instance_eval do
        extend ClassMethods
      end
    end


    # Defines a multimethod dispatching methods based on first argument's
    # ancestors.
    #
    # For example:
    # 
    #   multimethod :render
    #
    # Will define:
    #
    #   def render(x, *args)
    #   def render_Array(x, *args)
    #   def render_Hash(x, *args)
    #
    # Thus:
    #
    #   rcvr.render 4, :xyz
    #
    # Would attempt to send:
    #
    #   rcvr.render_Fixnum 4, :xyz
    #   rcvr.render_Integer 4, :xyz
    #   rcvr.render_Precision 4, :xyz
    #   rcvr.render_Numeric 4, :xyz
    #   rcvr.render_Comparable 4, :xyz
    #   rcvr.render_Object 4, :xyz
    #
    # Kernel is avoided and namespaces are removed from ancestor names.
    #
    # Array example:
    # 
    #   x = [ 4, 4.5 ]
    #   rcvr.render x, :xyz
    #
    # Dispatches to:
    #
    #   rcvr.render_Array x, :xyz
    #
    # Which will send to the first method where self.respond_to? is true:
    #
    #   rcvr.render_Array_of_Precision x, :xyz
    #   rcvr.render_Array_of_Numeric x, :xyz
    #   rcvr.render_Array_of_Comparable x, :xyz
    #   rcvr.render_Array_of_Object x, :xyz
    #
    # Hash example:
    # 
    #   x = { :a=> 4, :b => 4.5 }
    #   rcvr.render x, :xyz
    #
    # Dispatches to:
    #
    #   rcvr.render_Hash x, :xyz
    #
    # Which would send to the first method where self.respond_to? is true:
    #
    #   rcvr.render_Hash_of_Symbol_and_Precision x, :xyz
    #   rcvr.render_Hash_of_Symbol_and_Numeric x, :xyz
    #   rcvr.render_Hash_of_Symbol_and_Comparable x, :xyz
    #   rcvr.render_Hash_of_Symbol_and_Object x, :xyz
    #   rcvr.render_Hash_of_Object_and_Precision x, :xyz
    #   rcvr.render_Hash_of_Object_and_Numeric x, :xyz
    #   rcvr.render_Hash_of_Object_and_Comparable x, :xyz
    #   rcvr.render_Hash_of_Object_and_Object x, :xyz
    #
    #
    module ClassMethods
      def multimethod name, opts = nil
        opts ||= EMPTY_HASH
        prefix = opts[:class] ? 'self.' : ''

        class_eval(expr = <<"RUBY", __FILE__, __LINE__)
    def #{prefix}#{name} x, *args
      x.class.ancestors.each do | cls |
        next if cls == Kernel
        meth = :"#{name}_\#{cls.name.sub(/^.*::/, '')}" 
        return send(meth, x, *args) if respond_to? meth
      end
      raise ArgumentError, "Cannot find #{name}_* for \#{x.class}"
    end # def


    def #{prefix}#{name}_Array x, *args
      # Get a set of common ancestors of all element values.
      val_ancestors = x.inject(x.first.class.ancestors) do | a, xi | 
        a & xi.class.ancestors
      end
      val_ancestors.delete(::Kernel)

      # Find first method for ancestor named "#{name}_Array_of_<<val_ancestor>>".
      val_ancestors.each do | val_cls |
        meth = :"#{name}_Array_of_\#{val_cls.name.sub(/^.*::/, '')}" 
        return send(meth, x, *args) if respond_to? meth
      end

      raise ArgumentError, "Cannot find #{name}_Array_of_* for \#{x.class} using common ancestors \#{val_ancestors.inspect}" unless x.empty?
    end # def
      
      
    def #{prefix}#{name}_Hash x, *args
      # Get a set of common ancestors of all key elements.
      key_ancestors = x.keys.inject(x.keys.first.class.ancestors) do | a, xi | 
        a & xi.class.ancestors
      end
      key_ancestors.delete(::Kernel)

      # Get a set of common ancestors of all value elements.
      val_ancestors = x.values.inject(x.values.first.class.ancestors) do | a, xi | 
        a & xi.class.ancestors
      end
      val_ancestors.delete(::Kernel)

      # Find first method for ancestor named "#{name}_Hash_of_<<key_ancestor>>_and_<<val_ancestor>>".
      key_ancestors.each do | key_cls |
        val_ancestors.each do | val_cls |
          meth = :"#{name}_Hash_of_\#{key_cls.name.sub(/^.*::/, '')}_and_\#{val_cls.name.sub(/^.*::/, '')}" 
          return send(meth, x, *args) if respond_to? meth
        end
      end

      raise ArgumentError, "Cannot find #{name}_Hash_of_*_and_* for \#{x.class} using common key ancestors \#{key_ancestors.inspect} and value ancestors \#{val_ancestors.inspect}" unless x.empty?
    end # def

RUBY
        # $stderr.puts "#{expr}"
      rescue Exception => err
        raise err.class.new("#{err.inspect}\nin:\n#{expr}")
    end # multimethod

  end # module
end # module

end
