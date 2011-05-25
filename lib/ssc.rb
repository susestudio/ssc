module SSC
end

require 'handlers/all'
require 'argument_parser'
require 'yaml'

module SSC
  class Base
    def initialize(args)
      @args= ArgumentParser.new(args)
      @klass= @args.klass
      @options= get_config.merge(@args.options)
    end

    def run
      @klass.new(@options).send(@args.action)
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
