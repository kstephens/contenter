class SearchObject
  attr_accessor :search
  
  attr_reader :opts

  def initialize opts
    @search = ''
    opts ||= { }
    @opts = opts
    opts.each do | k, v |
      send("#{k}=", v)
    end
  end
end

