module SSC
  module Handler
    class UnknownFile < StandardError; end
    class File < Base

      cattr_reader :local_source
      @@local_source= 'files/'

      def create(path)
        full_path= initiate_file(path)
        [full_path]
      end
    end
  end
end
