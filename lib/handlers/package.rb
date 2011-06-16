module SSC
  module Handler
    class Package < Base

      cattr_reader :local_source
      @@local_source= 'software'

      def search(search_string)
        require_appliance_id(@options) do |appliance|
          software= appliance.search_software(search_string,
                      filter_options(@options, [:all_repos]))
          software.collect do |software|
            "#{software.name} v#{software.version}. Repo Id: #{software.repository_id}"
          end

        end
      end

      def list(type)
        raise "installed | selected package only" unless ['installed', 'selected'].include?(type)
        if @options[:r] || @options[:remote] || local_empty?
          require_appliance_id(@options) do |appliance|
            params= @options[:build_id]? {} : @options.slice(:build_id)
            software= appliance.send("#{type}_software")
            formatted_software= software.collect do |package|
              package.name + (package.version ? ( ' v'+package.version ) : "")
            end
            save(formatted_software) if type == "installed"
            formatted_software
          end
        else
          read
        end
      end

      def add(name)
        if @options[:r] || @options[:remote]
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
          save([ "add: #{name}" ])
        end
      end

      def remove(name)
        if @options[:r] || @options[:remote]
          require_appliance_id(@options) do |appliance|
            response= appliance.remove_package(name)
            ["State: #{response['state']}"]
          end
        else
          save([ "remove: #{name}" ])
        end
      end
    end
  end
end
