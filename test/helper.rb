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
  # To prevent printing of command line output
  class Thor::Shell::Basic
    def say(*args)
      args[0]
    end

    def print_table(*args)
      args[0]
    end
  end
end
