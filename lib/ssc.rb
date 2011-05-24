module SSC
end

require 'handlers/all'
require 'argument_parser'

module SSC
  class Base
    class << self
      def run(args)
        @args= ArgumentParser.new(args)
        @klass= @args.klass.new
        @klass.send(@args.action, @args.options)
      end
    end
  end
end
