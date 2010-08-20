# This file provides the transparent integration with the OpenURI
# library to allow you to simply include the gem and then use OpenURI
# like normal.
module OpenURI
  class << self
    alias original_open_uri open_uri
  
    # Monkey-patch open_uri to use our cache
    def open_uri(*args, &blk)
      OpenURI::DbCache::Page.fetch(*args, &blk)
    end

    # We know the monkey patch is working if it generates a cache 
    Test do
      OpenURI::DbCache::Page.destroy_all
      page = OpenURI::DbCache::Page.fetch 'http://localhost:4000/'
      assert page
      assert_equal 'Test Content', page.read
      cache = OpenURI::DbCache::Page.find_by_url 'http://localhost:4000/'
      assert cache
      assert_equal 'Test Content', cache.content
    end

    # This is duplicates from page.rb. Should we combine these?
    ForTest do
      def setup
        # Setup database to test setup
        ActiveRecord::Base.establish_connection \
          :adapter => 'sqlite3', :database => ':memory:'
    
        # Make sure the table does not exist
        ActiveRecord::Base.connection.drop_table \
          OpenURI::DbCache::Page.table_name rescue nil
    
        # Initialize the database
        OpenURI::DbCache.setup
      end
    end
  end
end