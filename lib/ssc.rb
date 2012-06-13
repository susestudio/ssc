module SSC
end

require 'thor'
require 'thor/group'
require 'directory_manager'
require 'handlers/all'
require 'yaml'

module SSC
  class Client < Handler::Base
    include DirectoryManager

    register Handler::Appliance, :appliance, "appliance", "manage appliances"
    register Handler::Repository, :repository, "repository","manage repositories"
    register Handler::Package, :package, "package", "manage packages"
    register Handler::Template, :template, "template", "manage templates"
    register Handler::OverlayFile, :file, "file", "manage files"
    register Handler::Build, :build, "build", "manage builds"

    desc "status", "show status of the appliance"
    require_appliance_id
    def status
      require_appliance_directory do |appliance, files|
        # Show appliance status
        say "Appliance: id: #{appliance.id} | name: #{appliance.name}"
        say "Status: #{appliance.status.state}"
        say appliance.status.issues        
        
        # Show additions
        say "\nAdditions : \n"
        say "\nPackages : \n"
        say_array files[:package]["add"] # Why not use invoke "s_s_c:handler:package:list", ["installed"]?
        say "\nRepositories : \n"
        say_array files[:repository]["add"]
        say "\nOverlay Files : \n"
        say_array(files[:file_list]["add"]) {|i| i.keys[0]}

        # Show removals
        say "\nRemovals : \n"
        say "\nPackages : \n"
        say_array files[:package]["remove"]
        say "\nRepositories : \n"
        say_array files[:repository]["remove"]
        say "\nOverlay Files :\n "
        say_array(files[:file_list]["remove"]) {|i| i.keys[0]}

        # Show banned
        say "\nBanned Packages : \n"
        say_array files[:package]["ban"]

        # Show unbanned
        say "\nUnBanned Packages : \n"
        say_array files[:package]["unban"]
      end
    end

    desc "checkout", "checkout the latest changes to an appliance"
    require_appliance_id
    def checkout
      params= {:appliance_id => options.appliance_id,
        :username     => options.username,
        :password     => options.password,
        :server => options.server}
      require_appliance_directory do |appliance, files|
        options= params.merge(:remote => true)
        invoke "s_s_c:handler:package:list", ["installed"], options
        invoke "s_s_c:handler:repository:list",  [], options
        invoke "s_s_c:handler:overlay_file:list",  [], options
      end
    rescue ApplianceDirectoryError
      require_appliance do |appliance|
        ApplianceDirectory.new(appliance.name, params).create
        Dir.chdir(appliance.name)
        options= params.merge(:remote => true)
        invoke "s_s_c:handler:package:list", ["installed"], options
        invoke "s_s_c:handler:repository:list",  [], options
        invoke "s_s_c:handler:overlay_file:list",  [], options
      end
    end

    desc "commit", "commit changes to studio"
    require_appliance_id
    def commit
      params= {:remote       => true,
        :appliance_id => options.appliance_id,
        :username     => options.username,
        :password     => options.password,
        :server => options.server}
      # Add, Remove, Ban and Unban  Packages
      package_file= PackageFile.new
      ["add", "remove", "ban", "unban"].each do |action|
        while package= package_file.pop(action)
          ap "Packge #{package}"
          ap "Oprions are #{package[:options]}"
          p invoke "s_s_c:handler:package:#{action}", [package[:name], package[:options]], params
        end
      end
      package_file.save

      # Add or Remove Repositories
      repository_file= RepositoryFile.new
      ["add", "remove"].each do |action|
        while repository= repository_file.pop(action)
          invoke "s_s_c:handler:repository:#{action}", [repository], params
        end
      end
      repository_file.save

      # Add Overlay Files
      file_list = FileListFile.new
      while file= file_list.pop("add")
        params= params.merge(file[:params])
        invoke "s_s_c:handler:overlay_file:add", [file[:full_path]], params
      end
      # Remove Overlay Files
      while file= file_list.pop("remove")
        invoke "s_s_c:handler:overlay_file:remove", [file[:name]], params
      end
      file_list.save
    end

    class << self
      def help(*args)
        message= <<HELP_MESSAGE 
Tasks:
  ssc checkout          # checkout the latest changes to an appliance
  ssc commit            # commit changes to studio
  ssc status            # show status of the appliance

  ssc appliance         # manage appliances
  ssc build             # manage builds
  ssc file              # manage files
  ssc package           # manage packages
  ssc repository        # manage repositories
  ssc template          # manage templates

  ssc help [TASK]       # Describe available tasks or one specific task
HELP_MESSAGE
       puts message
      end
    end
  end
end
