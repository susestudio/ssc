require 'studio_api'

$LOAD_PATH.unshift(File.dirname(__FILE__))

module SSC::Handler; end

require 'helper'

module SSC
  module Handler
    class Base < Thor

      include Helper

      API_URL= 'https://susestudio.com/api/v1/user'

      def initialize(*args)
        super

        optional_connection_options= filter_options(options, [:timeout, :proxy])
        connect(options.username, options.password, optional_connection_options)
        @not_local= true if options.remote?
      end

      no_tasks do 
        def say(*args)
          super(*args)
          args[0]
        end
      end
    end
  end
end

require 'build'
require 'appliance'
require 'repository'
require 'package'
require 'template'
require 'file'
