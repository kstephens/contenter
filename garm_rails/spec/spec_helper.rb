# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
begin
  env_file = ENV['RAILS_ENVIRONMENT'] || (File.dirname(__FILE__) + "/../config/environment")
  env_file = File.expand_path(env_file)
  require env_file
end
require 'spec'
require 'spec/matchers/change'

=begin
/var/lib/gems/1.8/gems/activesupport-2.2.2/lib/active_support/core_ext/module/aliasing.rb:33:in `alias_method': undefined method `evaluate_value_proc' for class `Spec::Matchers::Change' (NameError)
	from /var/lib/gems/1.8/gems/activesupport-2.2.2/lib/active_support/core_ext/module/aliasing.rb:33:in `alias_method_chain'
	from /var/lib/gems/1.8/gems/rspec-rails-1.1.12/lib/spec/rails/matchers/change.rb:8
class Spec::Matchers::Change
  def evaluate_value_proc *args
    $stderr.puts "WTF: #{args * "\n"}"
  end
end
=end

require 'spec/rails'
# require 'spec/rails/matchers/change'

# PATCH
# $:.
ENV['RUBYLIB'] = "#{File.expand_path(File.dirname(__FILE__) + "/../lib")}:#{ENV['RUBYLIB']}"

=begin
require 'rexml'
require 'rexml/formatters/pretty'
require 'lib/rexml/formatters/pretty'
=end
# $stderr.puts "#{__FILE__}: #{$:.inspect}"



Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  # 
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner
end
