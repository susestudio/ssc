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

      end

      module InstanceMethods

        def connect(user, pass, options = {})
          connection_options= filter_options(options, [:proxy, :timeout])
          @connection= StudioApi::Connection.new(user, pass, 'https://susestudio.com/api/v1/user', connection_options)
          StudioApi::Util.configure_studio_connection @connection
        end

        def filter_options(options, keys)
          keys.inject({}) do |out, key|
            options[key]? out.merge!({ key => options[key] }) : out
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
