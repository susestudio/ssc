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

        def require_appliance_id
          require_authorization
          config= get_config
          method_option :appliance_id, :type => :numeric, :required => true,
            :default => config["appliance_id"]
        end

        def allow_remote_option
          method_option :remote, :type => :boolean, :default => false
        end

        def get_config
          begin
            YAML::load File.read(File.join('.', '.sscrc'))
          rescue Errno::ENOENT
            return {'username' => nil, 'password' => nil, 'appliance_id' => nil}
          end
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

        def say_array(array, color= nil)
          # NOTE
          # Included for those methods that still return arrays for printing
          # Can be removed eventually
          # Still seems to be a nice way to format the text output of methods
          say array.join("\n"), color
        end

        def require_appliance
          if options.appliance_id
            yield(StudioApi::Appliance.find(options.appliance_id))
          else
            raise "Unable to find the appliance"
          end
        end
      end

    end
  end
end
