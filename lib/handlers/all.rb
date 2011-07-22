require 'studio_api'

$LOAD_PATH.unshift(File.dirname(__FILE__))

module SSC::Handler; end

require 'helper'

module SSC
  module Handler
    class Base < Thor

      include Helper
      include DirectoryManager

      API_URL= 'https://susestudio.com/api/v1/user'

      def initialize(*args)
        super

        optional_connection_options= filter_options(options, [:timeout, :proxy])
        connect(options.username, options.password, optional_connection_options)
        @not_local= true if options.remote?
      end
    end
  end
end

require 'appliance'
require 'repository'
require 'package'
require 'template'
require 'file'
require 'general_commands'
