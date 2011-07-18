require 'yaml'

module SSC
  module Handler
    module Helper

      def self.included(base)
        base.extend ClassMethods
        base.class_eval do

        end
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def require_authorization
          config= get_config
          method_option :username, :type => :string, :required => true, 
            :default => config["username"]
          method_option :password, :type => :string, :required => true, 
            :default => config["password"]
          method_option :proxy, :type => :string
          method_option :timeout, :type => :string
        end

        def get_config
          YAML::load File.read(File.join('.', '.sscrc'))
        end
      end

      module InstanceMethods

        # Establish connection to Suse Studio with username, password
        def connect(user, pass, connection_options)
          @connection= StudioApi::Connection.new(user, pass, self.class::API_URL, connection_options)
          StudioApi::Util.configure_studio_connection @connection
        end

        def filter_options(options, keys)
          keys.inject({}) do |out, key|
            (options.respond_to?(key) && options.send(key)) ? out.merge({ key => options.send(key) }) : out
          end
        end

        def require_appliance_id(options)
          if options[:appliance_id]
            yield(StudioApi::Appliance.find(options[:appliance_id]))
          else
            raise "Need the appliance id to run this method"
          end
        end
      end

    end
  end
end
