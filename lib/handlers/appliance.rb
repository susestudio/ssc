module SSC
  module Handler
    class Appliance

      def initialize(options= {})
        @options= options
      end
    
      def create
        puts @options.inspect
      end
      
      def list
      end

      def status
      end
    end
  end
end
