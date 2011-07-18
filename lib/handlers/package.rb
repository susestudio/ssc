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
      # import:
      #   name: <name>
      #   url: <url>
      cattr_reader :local_source
      @@local_source= 'software'

      # Search all available packages and patterns
      # @example 
      #   ssc package search <search_string>
      # @param [String] search_string 
      # @param [Hash] options
      # @option options [Boolean] :all_repos (true) search within current appliance or across all repositories.
      def search(search_string)
        require_appliance_id(@options) do |appliance|
          software= appliance.search_software(search_string, 
                                              @options.slice(:all_repos))
          software.collect do |software|
            "#{software.name} v#{software.version}. Repo Id: #{software.repository_id}"
          end
        end
      end

      # List all selected or installed packages in a given appliance
      # @example 
      #   ssc package list [installed|selected]
      # @param [String] type Either "selected" or "installed"
      # @param [Hash] options
      # @option options [:build_id] (nil) optional - specify which build's packages you would like to see.
      # @return [String] list of packages
      def list(type)
        raise ArgumentError, "installed | selected package only" unless ['installed', 'selected'].include?(type)
        if @not_local || no_local_list?
          require_appliance_id(@options) do |appliance|
            params= @options.slice(:build_id)
            software= appliance.send("#{type}_software")
            formatted_list= software.collect do |package|
              version= package.version ? { "version" => package.version } : nil
              {package.name => version}
            end
            save({type  => formatted_list})
          end
        else
          read(type)
        end
      end

      def add(name)
        if @not_local
          require_appliance_id(@options) do |appliance|
            response= appliance.add_package(name)
            case response['state']
            when "fixed"
              [ "Package Added. State: #{response['state']}" ]
            when "equal"
              [ "Package Not Added." ]
            when "broken"
              [ "Package Added. State: #{response['state']}.",
                "Please resolve dependencies" ]
            else
              [ "unknown code" ]
            end
          end
        else
          save({"add" => {name => nil}})
        end
      end

      def remove(name)
        if @not_local
          require_appliance_id(@options) do |appliance|
            response= appliance.remove_package(name)
            ["State: #{response['state']}"]
          end
        else
          save({"remove" => {name => nil}})
        end
      end

      def ban(name)
        if @not_local
          require_appliance_id(@options) do |appliance|
            response= appliance.ban_package(name)
            response.collect{|key, val| "#{key}: #{val}"}
          end
        else
          save({"ban" => {name => nil}})
        end
      end

      def unban(name)
        if @not_local
          require_appliance_id(@options) do |appliance|
            response= appliance.unban_package(name)
            response.collect{|key, val| "#{key}: #{val}"}
          end
        else
          save(({"unban" => {name => nil}}))
        end
      end
    end
  end
end
