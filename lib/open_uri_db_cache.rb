require 'rubygems'
require 'test_inline'
require 'active_record'
require 'singleton'
require 'open-uri'

module OpenURI
  module DbCache

    VERSION = {:major => 0, :minor => 0, :patch_level => 1}
    def VERSION.to_s
      [self[:major], self[:minor], self[:patch_level]] * '.'
    end
    Test do
      old = VERSION.dup
      VERSION.replace :major => 1, :minor => 1, :patch_level => 1
      assert_equal '1.1.1', VERSION.to_s
      VERSION.replace old
    end

    # Will initialize the database with the tables. 
    def self.setup
      OpenURI::DbCache::Schema.suppress_messages do
        OpenURI::DbCache::Schema.up unless OpenURI::DbCache::Page.table_exists?
      end
    end
    Test do
      # Setup database to test setup
      ActiveRecord::Base.establish_connection \
        :adapter => 'sqlite3', :database => ':memory:'
  
      # Make sure the table does not exist
      ActiveRecord::Base.connection.drop_table \
        OpenURI::DbCache::Page.table_name rescue nil
      assert !OpenURI::DbCache::Page.table_exists?

      # Initialize the database
      OpenURI::DbCache.setup
  
      # Verify the table does exist
      assert OpenURI::DbCache::Page.table_exists?
  
      # Make sure running again doesn't generate an error
      assert_nothing_raised {OpenURI::DbCache.setup}
    end

  end
end

require 'transparent'
require 'page'
require 'schema'
