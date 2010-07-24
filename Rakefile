require 'rake/gempackagetask'

desc "Run the automated testing"
task :test do
  # Run test server so we can do our testing with a real webserver
  $LOAD_PATH << 'lib'
  $test_server = fork {require 'test_server'}
  begin
    require 'net/http'
    Net::HTTP.get 'localhost', '/ping', 4000
  rescue
    sleep 1
    retry
  end
  puts 'Test server started...'
  at_exit do
    puts "Test server #{$test_server} shutting down...";
    Process.kill 'INT', $test_server
  end
  
  # Setup inline testing
  require 'rubygems'
  require 'test_inline'
  Test::Inline.setup 'lib'
  
  # Load library
  require 'open_uri_db_cache'
end

task :default => :test

spec = eval File.read('open_uri_db_cache.gemspec')
Rake::GemPackageTask.new spec do |pkg|
  pkg.need_tar = false
end

desc "Publish gem to rubygems.org"
task :publish => :package do
  `gem push pkg/#{spec.name}-#{spec.version}.gem`
end