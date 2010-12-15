#require 'action_controller/routing/route_set'
class ActionController::Routing::RouteSet
  def generate_code_with_debug(list, padding='  ', level = 0)
    result = generate_code_without_debug(list, padding, level)
    if level == 0
      $stderr.puts "generate_code_with_debug() =>\n#{result}"
    end
    result
  end
  alias :generate_code_without_debug :generate_code
  alias :generate_code :generate_code_with_debug
end

#require 'action_controller/routing/route'
class ActionController::Routing::Route
  def write_recognition_with_debug!
    result = write_recognition_without_debug!
      $stderr.puts "generate_code_with_debug() =>\n#{result}"
    result
  end
  alias :write_recognition_without_debug! :write_recognition!
  alias :write_recognition! :write_recognition_with_debug! 
end

