=begin
# See application_controller for the alternative to using this monkey patch
if RAILS_ENV=='development'

# Monkey-patch AR::Base to comment out the two lines as shown below per
# https://rails.lighthouseapp.com/projects/8994/tickets/1339-arbase-should-not-be-nuking-its-children-just-because-it-lost-interest
#
# The reason for this is that without this patch, certain models although their source is unchanged between requests,
# will generate errors upon the second request. config.cache_classes = false was another, more intrustive way to do this, below
# is actually the slimmer way to do keep development mode from being hosed.
#
# This is related to the time_zone_conversion errors which result upon the second request to content_versions/show/3 in dev mode
module ActiveRecord
  class Base
    def self.reset_subclasses #:nodoc:
      nonreloadables = []
      subclasses.each do |klass|
        unless ActiveSupport::Dependencies.autoloaded? klass
          nonreloadables << klass
          next
        end
        #klass.instance_variables.each { |var| klass.send(:remove_instance_variable, var) }
        #klass.instance_methods(false).each { |m| klass.send :undef_method, m }
      end
      @@subclasses = {}
      nonreloadables.each { |klass| (@@subclasses[klass.superclass] ||= []) << klass }
    end
  end
end

end # if RAILS_ENV=='development'
=end
