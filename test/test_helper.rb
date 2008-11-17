require 'rubygems'
require 'test/unit'
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter  => 'postgresql',
  :host     => 'localhost',
  :username => 'postgres',
  :password => '',
  :database => 'nested_transactions_test'
)

require File.dirname(__FILE__) + '/../lib/nested_transactions'
