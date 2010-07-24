# This file defines a test server using the rack inteface. We use
# an explict server (WEBrick) instead of running rackup so we can
# quite it for running our tests.

require 'rubygems'
require 'active_support'
require 'webrick'
require 'rack'

# Keep webrick quite
class ::WEBrick::HTTPServer; def access_log(config, req, res); end end
class ::WEBrick::BasicLog; def log(level, data); end end

# Allow testing suite to update last_modified and etag through signals
$last_modified = Time.now
$etag = '111111111'
trap("USR1") {$last_modified = Time.now}
trap("USR2") {$etag = $etag.succ}

app = Rack::Builder.app do
  response = lambda do |env|
    content = "Test Content"
    [200, {
      'Content-Type'  => 'text/plain',
      'Last-Modified' => $last_modified.httpdate,
      'ETag'          => $etag,
    }, content]
  end
  use Rack::ConditionalGet
  run response
end

Rack::Handler::WEBrick.run app, :Port => 4000