module SSC
end

require 'thor'
require 'thor/group'
require 'directory_manager'
require 'handlers/all'
require 'yaml'

module SSC
  class Client < Thor
    register Handler::Appliance, :appliance, "appliance", "manage appliances"
    register Handler::Repository, :repository, "repository","manage repositories"
    register Handler::Package, :package, "package", "manage packages"
    register Handler::Template, :template, "template", "manage templates"
    register Handler::OverlayFile, :file, "file", "manage files"
    register Handler::Status, :status, "(general) status", "show status of appliance"
    register Handler::Checkout, :checkout, "(general) checkout", "checkout the latest changes"
    register Handler::Commit, :commit, "(general) commit", "commit local changes"
  end
end
