module SSC
  module Handler
    class Package < Base

      # Structure of the 'software' file:
      #
      # ---
      # list:
      #   installed:
      #     <name>:
      #       version: <package.version>
      #     .
      #     .
      #     .
      #   selected:
      #     <name>: 
      #     .
      #     .
      #     .
      # add:
      #   <name>
      #   .
      #   .
      #   .
      # remove:
      #   <name>
      #   .
      #   .
      #   .
      # ban:
      #   <name>
      #   .
      #   .
      #   .
      # unban:
      #   <name>
      #   .
      #   .
      #   .

      no_tasks do 
        cattr_reader :local_source
        @@local_source= 'software'
      end

      desc 'package search SEARCH_STRING', 'search available packages and patterns'
      require_appliance_id
      method_option :all_repos, :type => :boolean, :default => true
      def search(search_string)
        require_appliance do |appliance|
          params= {:all_repos => options.all_repos} if options.all_repos
          software= appliance.search_software(search_string, params)
          software.collect do |software|
            say "#{software.name} v#{software.version}. Repo Id: #{software.repository_id}"
          end
        end
      end

      desc 'package list [selected|installed]', 'list all selected or installed packages'
      require_appliance_id
      allow_remote_option
      method_option :build_id, :type => :numeric
      def list(type)
        package_file= PackageFile.new
        raise Thor::Error, "installed | selected package only"  unless ['installed', 'selected'].include?(type)
        out= if options.remote? || package_file.empty_list?
          require_appliance do |appliance|
            params= {:build_id => options.build_id} if options.build_id
            software= appliance.send("#{type}_software")
            formatted_list= software.collect do |package|
              version= package.version ? { "version" => package.version } : nil
              package_file.push('list', {package.name => version})
            end
            package_file.save
          end
        else
          package_file.read
        end
        say out.to_yaml
      end

      desc 'package add NAMES', 'add packages to the appliance'
      require_appliance_id
      allow_remote_option
      def add(*names)
        names.each do |name|
          if options.remote?
            say "#{name}"
            require_appliance do |appliance|
              response= appliance.add_package(name)
              say case response['state']
              when "changed"
                "Package #{name} added. State: #{response['state']}."
              when "equal"
                "Package #{name} not added."
              when "broken"
                "Package #{name} added. State: #{response['state']}. Please resolve dependencies."
              else
                "unknown code"
              end
            end
          else
            package_file= PackageFile.new
            package_file.push('add', name)
            package_file.save
            say "#{name} marked for addition"
          end
        end
      end

      desc 'package remove NAMES', 'remove packages from the appliance'
      require_appliance_id
      allow_remote_option
      def remove(*names)
        names.each do |name|
          if options.remote?
            require_appliance do |appliance|
              response= appliance.remove_package(name)
              say case response['state']
              when "changed"
                "Package #{name} removed. State: #{response['state']}."
              when "equal"
                "Package #{name} not removed."
              else
                "unknown code"
              end
            end
          else
            package_file= PackageFile.new
            package_file.push('remove', name)
            package_file.save
            say "#{name} marked for removal"
          end
        end
      end

      desc 'package ban NAMES', 'ban packages from the appliance'
      require_appliance_id
      allow_remote_option
      def ban(*names)
        names.each do |name|
          if options.remote?
            require_appliance do |appliance|
              response= appliance.ban_package(name)
              response.collect{|key, val| "#{key}: #{val}"}
            end
          else
            package_file= PackageFile.new
            package_file.push('ban', name)
            package_file.save
            say "#{name} marked to be banned"
          end
        end
      end

      desc 'package unban NAMES', 'unban packages for the appliance'
      require_appliance_id
      allow_remote_option
      def unban(*names)
        names.each do |name|
          if options.remote?
            require_appliance do |appliance|
              response= appliance.unban_package(name)
              response.collect{|key, val| "#{key}: #{val}"}
            end
          else
            package_file= PackageFile.new
            package_file.push('unban', name)
            package_file.save
            say "#{name} marked to be unbanned"
          end
        end
      end
    end
  end
end
