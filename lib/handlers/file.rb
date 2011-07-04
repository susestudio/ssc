module SSC
  module Handler
    class File < Base

      cattr_reader :local_source
      @@local_source= 'files/'

      def create(path)
        require_appliance_id(@options) do |appliance|
          file_dir, file_name, local_path= initiate_file(path)
          File.open(full_path) do |file|
            StudioApi::File.upload(file, appliance.id,
                                   :path        => file_dir,
                                   :filename    => file_name,
                                   :permissions => "0755",
                                   :owner       => "root")
          end
          [full_path]
        end
      end
    end
  end
end
