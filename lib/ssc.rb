module SSC
end

require 'thor'
require 'thor/group'
require 'directory_manager'
require 'handlers/all'
require 'yaml'

module SSC
  class Client < Handler::Base

    include NewDirectoryManager

    register Handler::Appliance, :appliance, "appliance", "manage appliances"
    register Handler::Repository, :repository, "repository","manage repositories"
    register Handler::Package, :package, "package", "manage packages"
    register Handler::Template, :template, "template", "manage templates"
    register Handler::OverlayFile, :file, "file", "manage files"

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
        say_array files[:package]["add"]
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

    desc "status", "checkout the latest changes to an appliance"
    require_appliance_id
    def checkout
      params= {:appliance_id => options.appliance_id,
               :username     => options.username,
               :password     => options.password}
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
  end
end
