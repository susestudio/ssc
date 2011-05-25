module SSC
end

require 'handlers/all'
require 'argument_parser'
require 'yaml'

module SSC
  class Base
    def initialize(args)
      @args= ArgumentParser.new(args)
      @klass= @args.klass.new
      @config= get_config
    end

    def run
      @klass.send(@args.action, @config.merge(@args.options))
    end

    private

    def get_config
      config= if File.exist?(File.join(Dir.pwd, '.sscrc'))
        File.read(File.join(Dir.pwd, '.sscrc'))
      else
        ""
      end
      config = YAML::load(config) || {}
    end
  end
end
