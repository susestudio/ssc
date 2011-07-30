module SSC
  module Handler
    class GeneralCommand < Base
      class_options :timeout => :numeric, :proxy => :string
      include NewDirectoryManager
      include Helper
    end

    class Checkout < GeneralCommand
      desc "checkout the latest changes to an appliance"
      class_option :appliance_id, :type => :numeric, :default => nil

      def params 
        appliance_id= options.appliance ? options.appliance : @appliance_id
        @params= {:remote       => true,
                  :appliance_id => appliance_id,
                  :username     => @username,
                  :password     => @password}
      end

      def create_dir
        if options.appliance_id
          appliance= StudioApi::Appliance.find(options.appliance_id)
          dir= ApplianceDirectory.new(appliance.name, @params.stringify_keys)
          Dir.chdir(dir)
        end
      end

      def package_list
        invoke "s_s_c:handler:package:list", ["installed"], @params
      end

      def repository_list
        invoke "s_s_c:handler:repository:list",  [], @params
      end

      def file_list
        invoke "s_s_c:handler:overlay_file:list",  [], @params
      end

      def cleanup
        Dir.chdir('..') if options.appliance_id
      end
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
