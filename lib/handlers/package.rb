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
    end
  end
end
