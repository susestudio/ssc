module SSC
  module Handler
    class Repository < Base

      cattr_reader :local_source
      @@local_source= 'respositories'

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
        if @not_local || local_empty?
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
        if @not_local
          require_appliance_id(@options) do |appliance|
            response= appliance.add_repository(repo_ids)
            response.collect{|repos| repos.name}
          end
        else
          save(repo_ids.collect { |i| "add: #{i}"})
        end
      end

      def remove(*repo_ids)
        if @not_local
          require_appliance_id(@options) do |appliance|
            response= appliance.remove_repository(repo_ids)
            ["Removed #{repo_ids.join(", ")}"]
          end
        else
          save(repo_ids.collect { |i| "remove: #{i}"})
        end
      end
      
      def import(url, name) 
        if @not_local
          repository= StudioApi::Repository.import(url, name)
          ["Added #{repository.name}"]
        else
          save(["import: #{url}, #{name}"])
        end
      end
    end
  end
end
