module SSC
end

require 'thor'
require 'thor/group'
require 'directory_manager'
require 'handlers/all'
require 'yaml'

module SSC
  class Base < Thor
    register Handler::Appliance, :appliance, "appliance", "manage appliances"
    register Handler::Repository, :repository, "repository","manage repositories"
    register Handler::Package, :package, "package", "manage packages"
    #register Handler::Template, :template, "template", "manage templates"
    #register Handler::File, :file, "file", "manage files"
  end
end
