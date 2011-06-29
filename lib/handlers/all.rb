require 'studio_api'

$LOAD_PATH.unshift(File.dirname(__FILE__))

module SSC::Handler; end

require 'helper'

module SSC
  module Handler
    class Base

      include Helper
      include DirectoryManager

      def initialize(options= {})
        @options= options
        connect(@options[:username], 
                @options[:password], 
                options)
        @not_local= true if @options[:r] || @options[:remote]
      end
    end
  end
end

require 'appliance'
require 'repository'
require 'package'
require 'template'
require 'file'
