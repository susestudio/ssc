module SSC
  module Handler
    class GeneralCommand < Base
      class_options :timeout => :numeric, :proxy => :string
      include NewDirectoryManager
      include Helper
    end


    class Commit < GeneralCommand
      desc "commit changes to studio"

      def setup
        @params= {:remote       => true,
                  :appliance_id => @appliance_id,
                  :username     => @username,
                  :password     => @password}
      end

      def packages
        @package_file= PackageFile.new
        # Add, Remove, Ban and Unban  Packages
        ["add", "remove", "ban", "unban"].each do |action|
          while package= @package_file.pop(action)
            invoke "s_s_c:handler:package:#{action}", [package], @params
          end
        end
        @package_file.save
      end

      def repositories
        @repository_file= RepositoryFile.new
        # Add or Remove Repositories
        ["add", "remove"].each do |action|
          while repository= @repository_file.pop(action)
            invoke "s_s_c:handler:repository:#{action}", [repository], @params
          end
        end
        @repository_file.save
      end

      def files
        @file_list = FileListFile.new
        # Add Overlay Files
        while file= @file_list.pop("add")
          params= @params.merge(file[:params])
          invoke "s_s_c:handler:overlay_file:add", [file[:full_path]], params
        end
        # Add Overlay Files
        while file= @file_list.pop("remove")
          invoke "s_s_c:handler:overlay_file:remove", [file[:name]], @params
        end
        @file_list.save
      end

    end
  end
end
