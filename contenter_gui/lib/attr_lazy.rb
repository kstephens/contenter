# http://refactormycode.com/codes/219-activerecord-lazy-attribute-loading-plugin-for-rails
module AttrLazy
  module ClassMethods
    def attr_lazy_init_()
      @attr_lazy_columns = []
      class << self
        attr_accessor :attr_lazy_columns
        alias_method_chain :construct_finder_sql, :attr_lazy
      end
      
      include AttrLazy::InstanceMethods
    end
      
    def attr_lazy(*args)
      attr_lazy_init_ unless @attr_lazy_columns
      args.map!{|c| c.to_s}
      new_cols = args - (@attr_lazy_columns & args)
      @attr_lazy_columns |= args
      new_cols.each do |col|
        class_eval("def #{col}; read_lazy_attribute :#{col}; end", __FILE__, __LINE__)
      end
    end

    def column_names_for_join_base
      columns.collect{|c|c.name} - @attr_lazy_columns
    end
    
    def construct_finder_sql_with_attr_lazy(options)
      options = {:select => unlazy_column_list}.merge(options)
      construct_finder_sql_without_attr_lazy(options)
    end
    
    def unlazy_column_list
      (columns.collect{|c|c.name} - @attr_lazy_columns).collect {|c|
        "#{quoted_table_name}.#{connection.quote_column_name(c)}"
      }.join ','
    end
  end
  
  module InstanceMethods
  
    def read_lazy_attribute(att)
      att = att.to_s
      if @attributes.has_key? att
        @attributes[att]
      else
        @attributes[att] = self.class.find(self[self.class.primary_key], :select => att)[att]
      end
    end
    
  end
  
end

class ActiveRecord::Associations::ClassMethods::JoinDependency::JoinBase
  def column_names_with_alias
    unless @column_names_with_alias
      @column_names_with_alias = []
      ([active_record.primary_key] + (active_record.column_names_for_join_base - [active_record.primary_key])).each_with_index do |column_name, i|
        @column_names_with_alias << [column_name, "#{ aliased_prefix }_r#{ i }"]
      end
    end
    return @column_names_with_alias
  end
end

class << ActiveRecord::Base
  include AttrLazy::ClassMethods
end
