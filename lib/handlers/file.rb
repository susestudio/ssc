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

      def show(id)
        response= StudioApi::File.find(id)
        [ response.content ]
      end

      def diff(id)
        begin
          file_content= StudioApi::File.find(id).content
        rescue
          ["unable to connect"]
        end

        begin
          File.open('.tempfile', 'w') {|f| f.write(file_content)}
          diff= `diff .tempfile a`
        rescue
          ["diff not installed"]
        end
      end

      def list
        require_appliance_id(@options) do |appliance|
          if @not_local || local_empty?
            response= StudioApi::File.find(:all, :params => {:appliance_id => appliance.id})
            response.collect{|file| "#{File.join(file.path, file.filename)}\t file.checksum"}
          else
            list_local_files
          end
        end
      end
    end
  end
end
