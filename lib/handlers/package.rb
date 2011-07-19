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
        require_appliance_id(@options) do |appliance|
          params= {:all_repos => options.all_repos} if options.all_repos
          software= appliance.search_software(search_string, params)
          say_array software.collect do |software|
            "#{software.name} v#{software.version}. Repo Id: #{software.repository_id}"
          end
        end
      end

      desc 'package list [selected|installed]', 'list all selected or installed packages'
      require_appliance_id
      allow_remote_option
      method_option :build_id, :type => :numeric
      def list(type)
        say("installed | selected package only", :red) unless ['installed', 'selected'].include?(type)
        out= if options.remote? || no_local_list?
          require_appliance do |appliance|
            params= {:build_id => options.build_id} if options.build_id
            software= appliance.send("#{type}_software")
            formatted_list= software.collect do |package|
              version= package.version ? { "version" => package.version } : nil
              {package.name => version}
            end
            save(type, formatted_list)
            formatted_list
          end
        else
          read(type)
        end
        say out.to_yaml
      end


      desc 'package add NAME', 'add a package to the appliance'
      require_appliance_id
      allow_remote_option
      def add(name)
        if options.remote?
          require_appliance do |appliance|
            response= appliance.add_package(name)
            say case response['state']
            when "fixed"
              "Package Added. State: #{response['state']}"
            when "equal"
              "Package Not Added."
            when "broken"
              "Package Added. State: #{response['state']}. Please resolve dependencies"
            else
              "unknown code"
            end
          end
        else
          save("add", [ name ])
          say "#{name} marked for addition"
        end
      end

      desc 'package remove NAME', 'remove a package from the appliance'
      require_appliance_id
      allow_remote_option
      def remove(name)
        if options.remote?
          require_appliance do |appliance|
            response= appliance.remove_package(name)
            say "State: #{response['state']}"
          end
        else
          save("remove", [ name ])
          say "#{name} marked for removal"
        end
      end

      desc 'package ban NAME', 'ban a package from the appliance'
      require_appliance_id
      allow_remote_option
      def ban(name)
        if options.remote?
          require_appliance do |appliance|
            response= appliance.ban_package(name)
            response.collect{|key, val| "#{key}: #{val}"}
          end
        else
          save("ban", [ name ])
          say "#{name} marked to be banned"
        end
      end

      desc 'package unban NAME', 'unban a package for the appliance'
      require_appliance_id
      allow_remote_option
      def unban(name)
        if options.remote?
          require_appliance do |appliance|
            response= appliance.unban_package(name)
            response.collect{|key, val| "#{key}: #{val}"}
          end
        else
          save("unban", [ name ])
          say "#{name} marked to be unbanned"
        end
      end
    end
  end
end
