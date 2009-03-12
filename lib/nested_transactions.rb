module NestedTransactions
  VERSION = '1.0.0' unless defined?(VERSION)

  def self.init
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send(:include, self) if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    ActiveRecord::ConnectionAdapters::MysqlAdapter.send(:include, self)      if defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
  end

  def self.included(mod)
    [:begin_db_transaction, :commit_db_transaction, :rollback_db_transaction].each do |method_name|
      mod.alias_method_chain method_name, :nesting
    end
  end

  def begin_db_transaction_with_nesting
    @nested_transaction_count ||= 0
    @nested_transaction_count  += 1
    if @nested_transaction_count > 1
      execute "SAVEPOINT rails_nested_transaction_#{@nested_transaction_count}"
    else
      execute "BEGIN"
    end
  rescue ActiveRecord::StatementInvalid => e
    # There is an aborted transaction, so we have to reset our count.
    if e.message =~ /SAVEPOINT can only be used in transaction blocks/
      @nested_transaction_count = 0
      retry
    else
      raise e
    end
  end
  
  def commit_db_transaction_with_nesting
    raise 'Cannot commit transaction' if @nested_transaction_count == 0
    if @nested_transaction_count > 1
      execute "RELEASE SAVEPOINT rails_nested_transaction_#{@nested_transaction_count}"
    else
      execute "COMMIT"
    end
    @nested_transaction_count -= 1
  end
  
  def rollback_db_transaction_with_nesting
    raise 'Cannot rollback transaction' if @nested_transaction_count == 0
    if @nested_transaction_count > 1
      execute "ROLLBACK TO SAVEPOINT rails_nested_transaction_#{@nested_transaction_count}"
    else
      execute "ROLLBACK"
    end
    @nested_transaction_count -= 1
  end
end
