
class Symbol
  # Support Globalize-like .t interface for Contenter::Api#get(:phrase, self, ...).
  # Returns a StringTemplate object.
  #
  # in copy_*.yml:
  #
  #   cranky: "Hey #{name}!  Get off my #{object}!"
  #
  # in Ruby:
  #
  #   :cranky.t % { :name => 'kid', :object => 'keyboard' }
  #     => "Hey kid!  Get off my keyboard!"
  #
  def t(opts = nil)
    ((opts && opts[:content]) || Contenter::Api.current).get(:phrase, self, opts)
  end

  # Same as get_or_nil(:phrase, self)
  def t_or_nil(opts = nil)
    ((opts && opts[:content]) || Contenter::Api.current).get_or_nil(:phrase, self, opts)
  end


  # Shorthand for Symbol#t and subsequent #% operator:
  #
  #   :cranky % { :name => 'kid', :object => 'keyboard' }
  #
  # same as:
  #
  #   :cranky.t % { :name => 'kid', :object => 'keyboard' }
  #
  def %(arg)
    t % arg
  end
end

