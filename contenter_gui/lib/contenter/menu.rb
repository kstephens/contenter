module Contenter
  module MenuBase
    def initialize_hash opts = nil
      opts ||= { }
      opts.each do | k, v |
        send("#{k}=", v)
      end
      self
    end
    def initialize opts = nil
      opts ||= { }
      initialize_hash opts
      self
    end
  end

  class Menu
    include MenuBase
    attr_accessor :title, :link, :group, :priority

    def initialize opt = nil
      case opt
      when Symbol, String
        initialize([
                    opt.to_s.pluralize.humanize.titleize,
                    { :controller => opt.to_s.pluralize },
                   ])
      when Array
        initialize(:title => opt[0], :link => opt[1], :group => opt[2])
      when Hash
        initialize_hash(opt)
      else
        raise TypeError
      end
    end

    class Group
      include MenuBase
      attr_accessor :name, :title, :priority

      attr_accessor :menus

      def initialize opt = nil
        case opt
        when Symbol, String
          initialize [
                      opt.to_sym,
                      opt.to_s.humanize.titleize,
                     ]
        when Array
          initialize(:name => opt[0], :title => opt[1])
        when Hash
          initialize_hash(opt)
        else
          raise TypeError
        end
      end


      def menus
        @menus ||= [ ]
      end
    end

    class Configuration
      include MenuBase
      attr_accessor :menus, :groups

      def add_menus! a
        a.each do | e |
          case
          when nil
          when Hash === e && (ms = e.delete(:menus))
            ms.each do | x |
              next unless x
              self << Menu.new(x).initialize_hash(e)
            end
          else
            self << Menu.new(e)
          end
        end
        self
      end

      def add_groups! a
        a.each do | e |
          case e
          when nil
          else
            self << Menu::Group.new(e)
          end
        end
        self
      end

      def << x
        # pp x
        case x
        when nil
          return self
        when Menu
          a = (@menus ||= [ ])
        when Menu::Group
          a = (@groups ||= [ ])
        else
          raise TypeError
        end
        x.priority ||= a.size
        a << x
        self
      end

      def highlight! menus = self.menus
        menus.map! do | menu | 
          if yield menu
            menu = menu.dup
            menu.title = "<u>#{menu.title}</u>"
          end
          menu
        end
        menus
      end

      def select! menus = self.menus
        menus.reject! { | m | ! yield m }
      end

      def grouped menus = self.menus
        # Collect Menus into their Groups.
        group_menus = { }

        menus.sort do | a, b |
          a.priority <=> b.priority
        end.each do | menu |
          (group_menus[menu.group || :UNGROUPED] ||= [ ]) << menu
        end

        # Generate new prioritized Groups with their Menus.
        gi = -1
        groups.sort do | a, b |
          a.priority <=> b.priority
        end.map do | group |
          group = group.dup
          group.priority = (gi += 1)
          group.menus = group_menus[group.name]
          group
        end

      end

    end
  end

end



######################################################################

=begin

require 'pp'

mc = Contenter::Menu::Configuration.new
mc.add_groups!(
               [
                [ :content, 'Content', ], 
                [ :authorization, 'Authorization', ],
                [ :versions, 'Versions', ],
                [ :process, 'Process', ],
                [ :api, 'API', ],
                [ :other, 'Other', ],
               ]
               )
mc.add_menus!(
              [
               [ 'Search',
                 { :controller => :search, :action => :search },
                 :content,
               ],
               { :group => :content,
                 :menus => [
                            :content,
                            :content_key,
                            :content_type,
                            :language,
                            :country,
                            :brand,
                            :application,
                            :mime_type,
                           ],
               },
               { :group => :versions,
                 :menus => [
                            :content_version,
                            :version_list,
                            :version_list_name,
                           ],
               },
               { :group => :process,
                 :menus => [
                            :content_status,
                           ],
               },
               { :group => :authorization,
                 :menus => [
                            :user,
                            :role,
                            :capability,
                            :role_capability,
                           ],
               },
              ]
)

mc.highlight! { |m| m.link[:controller] == 'brand' }
pp mc.grouped

=end

