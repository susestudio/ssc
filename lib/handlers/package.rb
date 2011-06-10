module SSC
  module Handler
    class Package < Base
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
        require_appliance_id(@options) do |appliance|
          params= @options[:build_id]? {} : @options.slice(:build_id)
          software= appliance.send("#{type}_software")
          software.collect do |package|
            package.name + (package.version ? ( ' v'+package.version ) : "")
          end
        end
      end

      def add(*repo_ids)
        out = ["Repositories :"]
        require_appliance_id(@options) do |appliance|
          response= appliance.add_repository(repo_ids)
          response.collect{|repos| repos.name}
        end
      end
    end
  end
end
