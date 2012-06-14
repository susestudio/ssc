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
          server = 'susestudio.com'
          server = config["server"] if config["server"]
          method_option :server, :type => :string, :required => false, 
            :default => server
          if File.exists?("./.sscrc")
            method_option :username, :type => :string, :required => false, 
              :default => config["username"]
            method_option :password, :type => :string, :required => false, 
              :default => config["password"]
          else
            method_option :username, :type => :string, :required => true, 
              :default => config["username"]
            method_option :password, :type => :string, :required => true, 
              :default => config["password"]
          end
          method_option :proxy, :type => :string
          method_option :timeout, :type => :string
        end

        def require_appliance_id
          require_authorization
          config= get_config
          if File.exists?("./.sscrc")
            method_option :appliance_id, :type => :numeric, :required => false,
              :default => config["appliance_id"]
          else
            method_option :appliance_id, :type => :numeric, :required => false,
              :default => config["appliance_id"]
          end
        end

        def require_build_id
          config= get_config
          method_option :build_id, :type => :numeric, :required => true,
            :default => config["latest_build_id"]
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

        include DirectoryManager


        # Establish connection to Suse Studio with username, password
        def connect(user, pass, server, connection_options)
          api_url = "https://#{server}/api/v2/user"
          @connection= StudioApi::Connection.new(user, pass, api_url, connection_options)
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
          if array.is_a?(Array)
            array= array.collect {|i| yield(i)} if block_given?
            say array.join("\n"), color
          else
            say "\n"
          end
          array
        end

        def require_appliance
          if options.appliance_id
            yield(StudioApi::Appliance.find(options.appliance_id))
          else
            raise Thor::Error, "Unable to find the appliance"
          end
        end

        class ApplianceDirectoryError < StandardError; end

        def require_appliance_directory
          if File.exist?('./.sscrc')
            require_appliance do |appliance|
              files= {
                :package    => PackageFile.new,
                :repository => RepositoryFile.new,
                :file_list  => FileListFile.new }
                yield(appliance, files)
            end
          else
            raise ApplianceDirectoryError, 'Appliance directory not found'
          end
        end
      end

    end
  end
end
