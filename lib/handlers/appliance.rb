module SSC
  module Handler
    class Appliance < Base

      desc "create APPLIANCE_NAME", "Create an appliance"
      require_authorization
      method_option :source_id, :type => :numeric, :required => true
      method_option :arch, :type => :string
      def create(appliance_name)
        appliance_dir= File.join('.', appliance_name) 
        params= {:name => appliance_name}
        params.merge!(:arch => options.arch) if options.arch
        appliance= StudioApi::Appliance.clone(options.source_id, params)
        appliance_dir= self.class.create_appliance_directory(appliance_dir, options.username, options.password, appliance.id)
         say_array ["Created: ", appliance_dir, 
         File.join(appliance_dir, 'files'),
         File.join(appliance_dir, 'repositories'),
         File.join(appliance_dir, 'software') ]
      end
      
      desc "list", "list all appliances"
      require_authorization
      def list
        appliances= StudioApi::Appliance.find(:all)
        print_table appliances.collect{|i| [i.id, i.name]}
      end

      desc "info", "show details of a specific appliance"
      require_appliance_id
      def info
        appliance= StudioApi::Appliance.find(options.appliance_id)
        say_array ["#{appliance.id}: #{appliance.name}",
         "Parent: ( #{appliance.parent.id} ) #{appliance.parent.name}",
         "Download Url: #{download_url(appliance)}"]
      end

      desc "destroy", "destroy the current appliance (within appliance directory only)"
      require_appliance_id
      def destroy
        if appliance.destroy.code_type == Net::HTTPOK
          say 'Appliance Successfully Destroyed', :red
        else
          say_array ['There was a problem with destroying the appliance.',
           'Make sure that you\'re in the appliance directory OR',
           'Have provided the --appliance_id option']
        end
      end

      desc "status", "gives status of the appliance"
      require_appliance_id
      def status
        require_appliance do |appliance|
          response= appliance.status
          case response.state
          when 'error'
            say "Error: #{response.issues.issue.text}"
          when 'ok'
            say "Appliance Ok"
          end
        end
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
