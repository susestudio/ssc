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

      desc "repository search SEARCH_STRING", "search all available repositories"
      require_authorization
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

      desc "repository list", "list all repositories in a given appliance"
      require_appliance_id
      allow_remote_option
      def list
        repo_file= RepositoryFile.new
        list= if options.remote? || repo_file.empty_list?
          require_appliance do |appliance|
            appliance.repositories.collect do |repo|
              repo_file.push('list', { repo.id => { 'name' => repo.name, 
                                     'type'    => repo.type, 
                                     'base_system' => repo.base_system}})
            end
            repo_file.save
          end
        else
          repo_file['list']
        end
        say list.to_yaml
      end

      desc 'repository add REPO_IDS', 'add existing repositories to the appliance'
      require_appliance_id
      allow_remote_option
      def add(*repo_ids)
        if options.remote?
          require_appliance do |appliance|
            response= appliance.add_repository(repo_ids)
            say "Added"+( response.collect{|repos| repos.name} ).join(", ")
          end
        else
          repo_file= RepositoryFile.new
          repo_ids.each {|id| repo_file.push('add', id)}
          repo_file.save
          say "Marked the following for addition #{repo_ids.join(", ")}"
        end
      end

      desc 'repository remove REPO_IDS', 'remove existing repositories from appliance'
      require_appliance_id
      allow_remote_option
      def remove(*repo_ids)
        if options.remote?
          require_appliance do |appliance|
            response= appliance.remove_repository(repo_ids)
            say "Removed #{repo_ids.join(", ")}"
          end
        else
          repo_file= RepositoryFile.new
          repo_ids.each {|id| repo_file.push('remove', id)}
          repo_file.save
          say "Marked the following for removal #{repo_ids.join(", ")}"
        end
      end

      desc 'repository import URL NAME', 'import a 3rd party repository into appliance'
      require_authorization 
      allow_remote_option
      def import(url, name) 
        if options.remote?
          repository= StudioApi::Repository.import(url, name)
          say "Added #{repository.name} at #{url}"
        else
          repo_file= RepositoryFile.new
          repo_file.push('import', {"name" => name, "url" => url})
          repo_file.save
          say "Marked #{name} for import"
        end
      end
    end
  end
end
