require 'fileutils'

module SSC
  module Handler
    class Appliance < Base

      def create
      end
      
      def list
        appliances= StudioApi::Appliance.find(:all)
        appliances.collect{|i| "#{i.id}: #{i.name}"}
      end

      def show(id)
        appliance= StudioApi::Appliance.find(id)
        ["#{appliance.id}: #{appliance.name}",
         "Parent: ( #{appliance.parent.id} ) #{appliance.parent.name}",
         "Download Url: #{download_url(appliance)}" ]
      end

      private

      def download_url(appliance)
        if appliance.builds.empty?
          "No Build Yet"
        else
          appliance.builds.last.download_url
        end
      end
    end
  end
end
