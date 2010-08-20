class OpenURI::DbCache::Schema < ActiveRecord::Migration

  def self.up
    create_table OpenURI::DbCache::Page.table_name do |f|
      f.string :url, :null => false
      f.text :content, :null => false
      f.datetime :modified_at, :checked_at, :null => false
      f.string :etag
    end
  end

  def self.down
    drop_table OpenURI::DbCache::Page.table_name
  end

end