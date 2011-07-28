require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'yaml'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'ssc'


class Test::Unit::TestCase
  # You'll need to create this file(test/test_config.yaml) before you run the tests
  TEST_CONFIG= YAML::load(File.read(File.join(File.dirname(__FILE__), 'test_config.yaml')))
  APPLIANCES_CREATED= []
end
