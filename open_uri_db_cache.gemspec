Gem::Specification.new do |s|
  s.name = 'open_uri_db_cache'
  s.version = '0.0.2'
  s.homepage = 'http://wiki.github.com/eric1234/open_uri_db_cache/'
  s.author = 'Eric Anderson'
  s.email = 'eric@pixelwareinc.com'
  s.add_dependency 'activerecord'
  s.add_dependency 'test_inline'
  s.add_development_dependency 'rack'
  s.files = Dir['lib/**/*.rb']
  s.has_rdoc = true
  s.extra_rdoc_files << 'README'
  s.rdoc_options << '--main' << 'README'
  s.summary = 'Database-backed HTTP caching for open-uri'
  s.description = <<-DESCRIPTION
    A database-backed HTTP caching library for open_uri. Just use
    open_uri like normal and any URL's requested more than once will be
    served from the database to speed up requests and be a better net
    citizen to other web servers.
  DESCRIPTION
end