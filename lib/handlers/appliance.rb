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
        say "" # make sure terminal output starts on a new line
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
      def diff
         # get list of installed packages
         rpm_output = `rpm -qa --qf '%{NAME}#%{VERSION}-%{RELEASE}$'`.split('$').sort # TODO: bug check exit code
         rpm_output.delete_if {|x| x["gpg-pubkey"] } # remove SUSE gpg-pubkey package
         
         local_packages = Hash[rpm_output.map {|e| e.split('#')}]         
  	     
	     # read studio packages yaml and convert to RPM hash format
         studio_packages = {}
         package_file= PackageFile.new
         
         package_file.read["list"].map{|hash| hash.map{|k,v| studio_packages[k] = v["version"] }}
         studio_packages =  Hash[studio_packages.sort]
         
         p "Diffrence local - studio: #{local_packages.compare(studio_packages).count}"
         # return Hash with package name as a key and versions [local, studio]
         ap local_packages.compare(studio_packages)
         
         
         p "Diffrence studio - local: #{studio_packages.compare(local_packages).count}"
         # sas
         
         ap (studio_packages.to_a - local_packages.to_a).first
                     
         p "================================================"      
         p "Studio: #{studio_packages.to_a.count}"
         p "Local: #{local_packages.to_a.count}"
         
         diff = local_packages.diff(studio_packages)
         ap diff.first
         
         rpms = []
         diff.map do |k,v|
            package = { :name => k, :options => Hash[:version,v]}
            rpms << package
         end
         
         
                 
         say "You have #{diff.count} packages that differ from SUSE Studio application configuration:\n"
         #rpms.each_with_index{|p, n| say "#{n+1} #{p[:name]}-#{p[:options][:version]}"}
         
         # TODO: Compare the version, take the local package version and add package to Studio
         #rpms.each{|e| package_file.push('add', e)}
         #package_file.save
         
         #say "\n\033[32m#{diff.count} packages successfully added to software configuration file\033[0m"
         
         
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


class Hash
  def compare(other)
    self.keys.inject({}) do |memo, key|
      unless self[key] == other[key]
        memo[key] = [self[key], other[key]] 
      end
      memo
    end
  end
end


