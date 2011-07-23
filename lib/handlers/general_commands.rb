module SSC
  module Handler
    class GeneralCommand < Thor::Group
      class_options :timeout => :numeric, :proxy => :string
      include NewDirectoryManager
      include Helper

      API_URL= 'https://susestudio.com/api/v1/user'

      def initialize(*args)
        super(args)
        begin
          appliance_file= YAML::load(File.read(File.join(".", ".sscrc")))
          @appliance_id= appliance_file["appliance_id"]
          @username= appliance_file["username"]
          @password= appliance_file["password"]
          optional_connection_options= filter_options(options, [:timeout, :proxy])
          connect(@username, @password, optional_connection_options)
        rescue 
          raise Thor::Error, "Command can be executed only in appliance directory"
        end
      end
    end

    class Status < GeneralCommand
      desc "show status of the appliance"

      def get_files
        @package_file= PackageFile.new.read
        @repository_file= RepositoryFile.new.read
        @file_list_file= FileListFile.new.read
      end

      def show_appliance_status
        appliance= StudioApi::Appliance.find(@appliance_id)
        say "Appliance: id: #{appliance.id} | name: #{appliance.name}"
        say "Status: #{appliance.status.state}"
        say appliance.status.issues
      end

      def show_additions
        say "\nAdditions : \n"
        say "\nPackages : \n"
        say_array @package_file["add"]
        say "\nRepositories : \n"
        say_array @repository_file["add"]
        say "\nOverlay Files : \n"
        say_array(@file_list_file["add"]) {|i| i.keys[0]}
      end

      def show_removals
        say "\nRemovals : \n"
        say "\nPackages : \n"
        say_array @package_file["remove"]
        say "\nRepositories : \n"
        say_array @repository_file["remove"]
        say "\nOverlay Files :\n "
        say_array(@file_list_file["remove"]) {|i| i.keys[0]}
      end

      def show_banned
        say "\nBanned Packages : \n"
        say_array @package_file["ban"]
      end
      
      def show_unbanned
        say "\nUnBanned Packages : \n"
        say_array @package_file["unban"]
      end
    end

    class Checkout < GeneralCommand
      desc "checkout the latest changes to an appliance"

      def params 
        @params= {:remote       => true,
                  :appliance_id => @appliance_id,
                  :username     => @username,
                  :password     => @password}
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
