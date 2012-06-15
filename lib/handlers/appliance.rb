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

      desc "appliance diff", "difference between RPMs installed on current machine and SUSE Studio configuration"
      def diff
        # get list of installed packages
        rpm_output = `rpm -qa --qf '%{NAME}#%{VERSION}-%{RELEASE}$'`.split('$').sort # TODO: bug check exit code
        rpm_output.delete_if {|x| x["gpg-pubkey"] } # remove SUSE gpg-pubkey package
      
        raise "\n*** Command 'rpm 'not found: ensure RPM is installed #{$?.exitstatus}" unless $?.success?
             
        local_packages = Hash[rpm_output.map {|e| e.split('#')}]         
  	     
	     # read software yaml and convert to RPM hash format
         studio_packages = {}
         package_file= PackageFile.new
         
         package_file.read["list"].map{|hash| hash.map{|k,v| studio_packages[k] = v["version"] }}
         studio_packages =  Hash[studio_packages.sort]
         
         number = studio_packages.compare(local_packages).count + local_packages.compare(studio_packages).count
                     
         if number > 0
           say "You have #{number} packages that differ from SUSE Studio application configuration:\n"
                    
           # compare studio packages with locally installed packages
           # if studio package list differ from local package list, add package to remove section
           # returns Hash of hashes with package name as a key and versions [studio, local]
           
           say "\n\033[31mremove:\033[0m"
           studio_packages.compare(local_packages).map do |name, version|
              package = { :name => name, :options => Hash[:version,version.first]}
              package_file.push('remove', package) # downgrade if version.last
              say "#{name}-#{version.first}"
           end
           
           # compare locally installed packages with studio packages
           # if local package list differ from studio, add package to add section
           # returns Hash of hashes with package name as a key and versions [local, studio]
           
           say "\n\033[32madd:\033[0m"
           local_packages.compare(studio_packages).map do |name, version|
              package = { :name => name, :options => Hash[:version,version.first]} # commit local package version if differ from studio 
              package_file.push('add', package)
              say "#{name}-#{version.first}"
           end
  
                    
           #say "You have #{studio_packages.compare(local_packages).count} packages that differ from SUSE Studio application configuration:\n"
           #ap studio_packages.compare(local_packages)
           
           if package_file.save # write to software file
              say "#{number} packages changed in the software configuration file", :green
           end
           
         else
           say "You SUSE Studio software configuration is up-to-date", :green  
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


