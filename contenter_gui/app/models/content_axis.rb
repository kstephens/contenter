
module ContentAxis
  def self.included target
    super
    target.instance_eval do
      before_save :initialize_axis_defaults!
    end
  end

  def initialize_axis_defaults!
    self.name ||= code
    self.description ||= name
  end

end
