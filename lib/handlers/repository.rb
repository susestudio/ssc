module SSC
  module Handler
    class Repository < Base

      include DirectoryManager
      
      manage 'repositories'
      
      def search(search_string)
        params= {:filter => search_string}
        params= params.merge({:base_system => @options[:base_system]}) if @options[:base_system]
        repos= StudioApi::Repository.find(:all, :params => params)
        repos.collect do |repo|
          "#{repo.id}.) #{repo.name}: #{repo.base_url}
          #{[repo.matches.software_name].flatten.join(', ')}\n"
        end
      end

      def list
        if @options[:r] || @options[:remote] || local_empty?
          save(require_appliance_id(@options) do |appliance|
            appliance.repositories.collect do |repo|
              "#{repo.id}.) #{repo.name} : #{repo.type} : #{repo.base_system}"
            end
          end)
        else
          read
        end
      end

      def add(*repo_ids)
        if @options[:r] || @options[:remote]
          require_appliance_id(@options) do |appliance|
            response= appliance.add_repository(repo_ids)
            response.collect{|repos| repos.name}
          end
        else
          save(repo_ids.collect { |i| "add: #{i}"})
        end
      end
    end
  end
end
