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

        def authorize(user, pass)
          @connection= StudioApi::Connection.new(user, pass, 'https://susestudio.com/api/v1/user')
          StudioApi::Util.configure_studio_connection @connection
        end

      end

    end
  end
end
