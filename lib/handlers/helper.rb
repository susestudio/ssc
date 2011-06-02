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
          connection_options= filter_options(options)
          @connection= StudioApi::Connection.new(user, pass, 'https://susestudio.com/api/v1/user', connection_options)
          StudioApi::Util.configure_studio_connection @connection
        end

        def filter_options(options)
          [:proxy, :timeout].inject({}) do |out, key|
            options[key]? out.merge!({ key => options[key] }) : out
          end
        end

      end

    end
  end
end
