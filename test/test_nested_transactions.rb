require File.dirname(__FILE__) + '/test_helper.rb'

class CreateTables < ActiveRecord::Migration  
  def self.up
    create_table :books do |t|
      t.column :title, :string
      t.column :author, :string
    end
  end

  def self.down
    drop_table :books
  end
end

NestedTransactions.init

class Book < ActiveRecord::Base
end

class TestNestedTransactions < Test::Unit::TestCase
  def setup
    CreateTables.up
  end

  def teardown
    CreateTables.down
  end
  
  N = 20
  def test_nested_transactions
    (2 * N).times do |i|
      ActiveRecord::Base.connection.begin_db_transaction
      assert_equal i, Book.find(:all).size
      Book.create(:title => "Book #{i}", :author => 'Justin Balthrop')
    end
    
    N.times do |i|
      assert_equal 2 * N, Book.find(:all).size
      ActiveRecord::Base.connection.commit_db_transaction
    end
      
    N.times do |i|
      ActiveRecord::Base.connection.rollback_db_transaction
      assert_equal N - i - 1, Book.find(:all).size
    end
  end
end
