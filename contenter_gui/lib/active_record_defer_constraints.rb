ActiveRecord::Base.class_eval do
  # Defer all DEFERRABLE CONSTRAINTS in a transaction.
  def defer_constraints
    self.class.transaction do
      self.connection.execute("SET CONSTRAINTS ALL DEFERRED");
      yield
    end
  end
end
