module SSC
  module Handler
    class Repository < Base

      # Structure of the 'repositories' file:
      #
      # ---
      # list:
      #   <id>:
      #     name: <repo.name>
      #     type: <repo.type>
      #     base_system: <repo.base_url>
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
      # import:
      #   name: <name>
      #   url: <url>
      no_tasks do
        cattr_reader :local_source
        @@local_source= 'repositories'
      end

      # @param [String] search_string for respository search
      # @param [Hash] options
      # @option options [String] :base_system (nil) optional base system specification
      desc "search SEARCH_STRING", "search all available repositories"
      require_appliance_id
      method_option :base_system, :type => :string
      def search(search_string)
        params= {:filter => search_string}
        params= params.merge({:base_system => options.base_system}) if options.base_system
        repos= StudioApi::Repository.find(:all, :params => params)
        say_array(repos.collect do |repo|
          "#{repo.id}.) #{repo.name}: #{repo.base_url}
          #{[repo.matches.software_name].flatten.join(', ')}\n"
        end)
      end

      desc "list", "list all repositories in a given appliance"
      require_appliance_id
      allow_remote_option
      def list
        if options.remote? || local_empty?
          list= require_appliance do |appliance|
            appliance.repositories.collect do |repo|
              { repo.id => { 'name'        => repo.name, 
                             'type'        => repo.type, 
                             'base_system' => repo.base_system}}
            end
          end
          save({'list' =>  list}) unless options.remote?
        end
        say read('list')
      end

      # @param [Array] repo_ids
      desc 'add REPO_IDS', 'add existing repositories to the appliance'
      require_appliance_id
      allow_remote_option
      def add(*repo_ids)
        if options.remote?
          require_appliance do |appliance|
            response= appliance.add_repository(repo_ids)
            say "Added"+( response.collect{|repos| repos.name} ).join(", ")
          end
        else
          add_items('add', repo_ids)
        end
      end

      # @param [Array] repo_ids
      desc 'remove REPO_IDS', 'remove existing repositories from appliance'
      require_appliance_id
      allow_remote_option
      def remove(*repo_ids)
        if options.remote?
          require_appliance do |appliance|
            response= appliance.remove_repository(repo_ids)
            say "Removed #{repo_ids.join(", ")}"
          end
        else
          add_items('remove', repo_ids)
        end
      end

      desc 'import URL NAME', 'import a 3rd party repository into appliance'
      allow_remote_option
      def import(url, name) 
        if options.remote?
          repository= StudioApi::Repository.import(url, name)
          say "Added #{repository.name} at #{url}"
        else
          add_item("import", [{"name" => name, "url" => url}])
        end
      end
    end
  end
end
