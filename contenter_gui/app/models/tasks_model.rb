
# Mixin support for tasks column.
module TasksModel
  def self.included target
    super
    target.extend(ClassMethods)
    target.class_eval do 
      include InstanceMethods

      # Plugins can set this to true to require tasks to be defined before saving.
      def self.requires_tasks; @requires_tasks; end
      def self.requires_tasks= x; @requires_tasks = x; end

      before_validation :normalize_tasks!
    end
  end

  module ClassMethods
  end # module

  module InstanceMethods
    EMPTY_STRING = "".freeze 

    def validate_tasks_is_not_empty!
      errors.add(:tasks, "tasks is empty") if tasks_list.empty?
    end

    def subtasks
      return [] unless respond_to?(:content_versions)
      content_versions.map(&:tasks_list).inject([]) do |all, ts|
        all.push(*ts)
      end.sort.uniq.join(" ")
    end

    # Normalize so all tasks have a single whitespace around them such that:
    #
    #   contents.tasks LIKE '% 123 %' will match.
    #
    def normalize_tasks!
      x = tasks_list.join(' ')
      self.tasks = x.empty? ? '' : ' ' + x + ' '
    end

    # Returns an Array of task Integers.
    def tasks_list
      (self.tasks || EMPTY_STRING).scan(/\d+/).map{|x| x.to_i}.sort.uniq
    end
  end # module
end

