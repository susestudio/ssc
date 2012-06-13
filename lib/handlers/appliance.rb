require 'active_support/core_ext'

module SSC
  module Handler
    class Appliance < Base

      desc "appliance create APPLIANCE_NAME", "Create an appliance"
      require_authorization
      method_option :source_id, :type => :numeric, :required => true
      method_option :arch, :type => :string
      def create(appliance_name)
        appliance_dir= File.join('.', appliance_name) 
        params= {:name => appliance_name}
        params.merge!(:arch => options.arch) if options.arch
        appliance= StudioApi::Appliance.clone(options.source_id, params)
        appliance_params= {
          :username => options.username,
          :password => options.password,
          :appliance_id => appliance.id }
        appliance_dir= ApplianceDirectory.new(appliance_name, appliance_params)
        appliance_dir.create
        say_array(["Created: ", appliance_dir.path] + appliance_dir.files.values)
      end
      
      desc "appliance list", "list all appliances"
      require_authorization
      def list
        appliances= StudioApi::Appliance.find(:all)
        print_table([["id", "name"]]+appliances.collect{|i| [i.id, i.name]})
      end

      desc "appliance info", "show details of a specific appliance"
      require_appliance_id
      def info
        appliance= StudioApi::Appliance.find(options.appliance_id)
        say_array ["#{appliance.id}: #{appliance.name}",
         "Parent: ( #{appliance.parent.id} ) #{appliance.parent.name}",
         "Download Url: #{download_url(appliance)}"]
      end

      desc "appliance destroy", "destroy the current appliance (within appliance directory only)"
      require_appliance_id
      def destroy
        require_appliance do |appliance|
          if appliance.destroy.code_type == Net::HTTPOK
            say 'Appliance Successfully Destroyed', :red
          else
            say_array ['There was a problem with destroying the appliance.',
                       'Make sure that you\'re in the appliance directory OR',
                       'Have provided the --appliance_id option']
          end
        end
      end

      desc "appliance status", "gives status of the appliance"
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

      desc "appliance diff", "returns difference between RPMs installed on current machine and Studio configuration"
      #require_appliance_id
      def diff
         p "******************** RPM LIST ***********************"
         # get list of installed packages
         rpm_list = `rpm -qa --qf '%{NAME}#%{VERSION}-%{RELEASE}$'`.split('$').sort
         local_packages = Hash[rpm_list.map {|el| el.split('#')}]
         #p local_packages
  	     
	     p "******************** STUDIO CONFIG ******************"
	     # read studio packages yaml and convert to RPM hash format
         studio_config = {}
         
         PackageFile.new().read["list"].map{|hash| hash.map{|k,v| studio_config[k] = v['version'] }}
         studio_config =  Hash[studio_config.sort]
         #p studio_config
         
         p "******************** DIFFERENCE *********************"
         diff = local_packages.diff(studio_config)
         
         
# CONVERT TO YAML HASH
#          hash = {}
#          rpm_list = `rpm -qa --qf '%{NAME}#%{VERSION}-%{RELEASE}$'`.split('$').sort
#          rpm_list.each{|e| hash[e.split('#').first] = Hash["version", e.split('#').last]}
#          rpm_list_hash = hash.collect{|k, v| Hash[k,v]}
#          ap rpm_list_hash.class
#          ap PackageFile.new().read["list"].class
#          
#          ap rpm_list_hash.count
#          ap PackageFile.new().read["list"].count
#          
#          ap PackageFile.new().read["list"] - rpm_list_hash
         
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




