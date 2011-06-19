module SSC
end

require 'directory_manager'
require 'handlers/all'
require 'argument_parser'
require 'yaml'

module SSC
  class Base
    def initialize(args)
      @args= ArgumentParser.new(args)
      @klass= @args.klass
      @options= get_config.merge(@args.options) if @klass
    end

    def run
      return unless @klass
      begin
        out= if @args.action_arguments.empty?
          @klass.new(@options).send(@args.action)
        else
          @klass.new(@options).send(@args.action, *@args.action_arguments)
        end
      rescue ArgumentError
        print "Incorrect number of arguments provided"
        self.class.print_usage
      rescue Errno::ECONNREFUSED, SocketError
        print "Could not connect to Suse Studio"
      rescue UnkownOptionError
        print "Couldn't parse the arguments provided" 
        self.class.print_usage
      end

      print(out)
    end

    def self.print_usage
      usage= <<USAGE
ssc (Suse Studio Client): Usage
All commands marked with (*) can be run without explicitly mentioning the appliance id from the appliance directory. If you'd rather run the command outside an appliance directory, you will need to specify the --appliance_id, --username and --password.

appliance
    create <appliance_name> --source_id <source_appliance_id> : Creates a new appliance and an appliance directory for local caching of modifications
    (*) list : Lists all users appliances
    show <appliance_id> : Shows details of the current appliance
    (*) destroy : Destroys current appliance
    (*) status : Show's status of current appliance

package
    search <search_string> [--all_repos] : Search for software
    (*) list [installed|selected] : List software in the current appliance
    (*) add <name> : Add a package
    (*) remove <name> : Remove a package
    (*) ban <name>
    (*) unban <name>

repository
   search <search_string> [--base_system]
   (*) list
   (*) add <repo ids> : e.g. ssc add 12417 82523 35313
   (*) remove <re ids>

template
    list : Lists available template sets
    show <name> : Lists appliances in the template set <name>

USAGE
      print usage
    end

    def print(output)
      puts output
    end

    def get_config
      config= if File.exist?(File.join(Dir.pwd, '.sscrc'))
        File.read(File.join(Dir.pwd, '.sscrc'))
      else
        ""
      end
      config = (YAML::load(config) || {}).symbolize_keys
    end
  end
end
