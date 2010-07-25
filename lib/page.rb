# Data object to store feed info in database.
class OpenURI::DbCache::Page < ActiveRecord::Base
  set_table_name 'open_uri_cache_page'

  cattr_accessor :fetch_limit
  self.fetch_limit = 4.hours

  # Use same options are OpenURI so we can pass the same params
  # to the real method
  def self.fetch(url, *args, &blk)
    OpenURI::DbCache.setup
    headers = args.last.is_a?(Hash) ? args.pop : {}
    url = url.to_s
    page = find_by_url url
    if !page || page.checked_at < fetch_limit.ago

      if page
        # Try to generate a 304 Not Modified status if we have old info
        headers['If-Modified-Since'] = page.modified_at.httpdate
        headers['If-None-Match'] = page.etag if page.etag.present?
      else
        page = new :url => url
      end

      page.checked_at = Time.now
      begin
        io = OpenURI.original_open_uri url, headers
        return block_given? ? blk[io] : io unless
          io.content_type =~ /text/ || io.content_type =~ /xml/
        page.modified_at = io.last_modified || Time.now rescue Time.now
        page.etag = io.meta['etag'] if io.meta['etag'].present?
        page.content = io.read
      rescue OpenURI::HTTPError # Result was something other than 200
        raise unless $!.io.status[0] == '304'
      end
      page.save!
    end
    io = StringIO.new page.content
    block_given? ? blk[io] : io
  end

  Test 'not cached' do
    OpenURI::DbCache::Page.destroy_all
    page = OpenURI::DbCache::Page.fetch 'http://localhost:4000/'
    assert page
    assert_equal 'Test Content', page.read
    assert OpenURI::DbCache::Page.find_by_url('http://localhost:4000/')
  end

  Test 'cached recently (do not hit at all)' do
    # Initial fetch just to put in cache
    OpenURI::DbCache::Page.destroy_all
    OpenURI::DbCache::Page.fetch 'http://localhost:4000/'
    cache = OpenURI::DbCache::Page.find_by_url 'http://localhost:4000/'
    old = cache.checked_at

    # We know it doesn't even try if the "checked_at" is not changed
    sleep 1
    OpenURI::DbCache::Page.fetch 'http://localhost:4000/'
    cache.reload
    assert_equal old, cache.checked_at

    # Make sure if it gets old the checked_at does change
    cache.etag = nil
    cache.modified_at = 1.day.ago
    cache.checked_at = 1.day.ago
    cache.save!
    OpenURI::DbCache::Page.fetch 'http://localhost:4000/'
    cache.reload
    assert 1.day.ago < cache.checked_at
  end

  Test 'last modified cache trigger' do
    # Initial fetch just to put in cache
    OpenURI::DbCache::Page.destroy_all
    OpenURI::DbCache::Page.fetch 'http://localhost:4000/'
    cache = OpenURI::DbCache::Page.find_by_url 'http://localhost:4000/'

    # Ensure it actually tries to fetch
    cache.checked_at = 1.day.ago
    cache.etag = nil

    # Update the cache manually so we know it was not updated
    cache.content = cache.content.gsub 'Test', 'Tests'

    cache.save!

    # First fetch doesn't update cache as the last-modified not updated
    page = OpenURI::DbCache::Page.fetch 'http://localhost:4000/'
    assert_equal 'Tests Content', page.read

    # Update last modified
    Process.kill 'USR1', $test_server

    cache.checked_at = 1.day.ago
    cache.etag = nil
    cache.save!

    # Our cache should be restored as it has expired
    page = OpenURI::DbCache::Page.fetch 'http://localhost:4000/'
    assert_equal 'Test Content', page.read
  end

  Test 'etag cache trigger' do
    # Initial fetch just to put in cache
    OpenURI::DbCache::Page.destroy_all
    OpenURI::DbCache::Page.fetch 'http://localhost:4000/'
    cache = OpenURI::DbCache::Page.find_by_url 'http://localhost:4000/'

    # Ensure it actually tries to fetch
    cache.checked_at = 1.day.ago
    cache.modified_at = 1.day.ago

    # Update the cache manually so we know it was not updated
    cache.content = cache.content.gsub 'Test', 'Tests'

    cache.save!

    # First fetch doesn't update cache as the etag not updated
    page = OpenURI::DbCache::Page.fetch 'http://localhost:4000/'
    assert_equal 'Tests Content', page.read

    # Update etag
    Process.kill 'USR2', $test_server

    cache.checked_at = 1.day.ago
    cache.modified_at = 1.day.ago
    cache.save!

    # Our cache should be restored as it has expired
    page = OpenURI::DbCache::Page.fetch 'http://localhost:4000/'
    assert_equal 'Test Content', page.read
  end

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