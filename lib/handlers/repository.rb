module SSC
  module Handler
    class Repository < Base
      
      def search(search_string)
        params= {:filter => search_string}
        params= params.merge({:base_system => @options[:base_system]}) if @options[:base_system]
        repos= StudioApi::Repository.find(:all, :params => params)
        repos.collect do |repo|
          "#{repo.name}: #{repo.base_url}
          #{[repo.matches.software_name].flatten.join(', ')}\n"
        end
      end
    end
  end
end
