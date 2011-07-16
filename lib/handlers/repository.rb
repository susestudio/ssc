module SSC
  module Handler
    class Repository < Base

      # Structure of the 'repositories' file:
      #
      # ---
      # list:
      #   <id>:
      #     name: <repo.name>
      #     base_url: <repo.base_url>
      #   .
      #   .
      #   .
      # add:
      #   <id>
      #   .
      #   .
      #   .
      # remove:
      #   <id>
      #   .
      #   .
      #   .
      cattr_reader :local_source
      @@local_source= 'respositories'

      # Search all available repositories 
      # @example
      #   ssc repository search <search_string>
      # @param (String) search_string for respository search
      # @param (Hash) options
      # @option options [String] :base_system (nil) optional base system specification
      def search(search_string)
        params= {:filter => search_string}
        params= params.merge({:base_system => @options[:base_system]}) if @options[:base_system]
        repos= StudioApi::Repository.find(:all, :params => params)
        repos.collect do |repo|
          "#{repo.id}.) #{repo.name}: #{repo.base_url}
          #{[repo.matches.software_name].flatten.join(', ')}\n"
        end
      end

      # List all repositories in a given appliance
      # @example
      #   ssc repository list
      def list
        if @not_local || local_empty?
          list= require_appliance_id(@options) do |appliance|
            appliance.repositories.collect do |repo|
              { repo.id => { 'name'        => repo.name, 
                             'type'        => repo.type, 
                             'base_system' => repo.base_system}}
            end
          end
          save({'list' =>  list}, 'w')
        else
          read('list')
        end
      end

      # Add an existing repository to the appliance
      # @example
      #   ssc repository add 13412 45636 92168
      # @param (Array) repo_ids
      def add(*repo_ids)
        if @not_local
          require_appliance_id(@options) do |appliance|
            response= appliance.add_repository(repo_ids)
            response.collect{|repos| repos.name}
          end
        else
          save(repo_ids.collect { |i| "#{i}: add"})
        end
      end

      def remove(*repo_ids)
        if @not_local
          require_appliance_id(@options) do |appliance|
            response= appliance.remove_repository(repo_ids)
            ["Removed #{repo_ids.join(", ")}"]
          end
        else
          save(repo_ids.collect { |i| "#{i}: remove"})
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
