module SSC
  module Handler
    class File < Base

      cattr_reader :local_source
      @@local_source= 'files/'

      # must be run in appliance directory
      # takes the following argument:
      # file_path => (relative positions("." and "..") allowed and ~ for home directory allowed)
      # takes the following options:
      # --path="/path/to/file_directory/"   => optional (by default it is the path of the file on the local system)
      # --name="file_name"                  => optional (by default it is the name of the file on the local system)
      # --permissions="0766"                => optional (default: 0755)
      # --owner="user"                      => optional (default: root)
      def create(path)
        absolute_path= File.absolute_path('~/.ssh/config'.gsub('~', ENV['HOME']))
        optional_file_params= {:permissions => "0755", :owner => "root"}
        optional_file_params.merge!(@options.reject{|k,v| ![:path, :name, :permissions, :owner].include?(k)})
        file_dir, file_name= File.split(absolute_path)
        file_params= ( { :path => file_dir, :filename => file_name } ).merge optional_file_params
        require_appliance_id(@options) do |appliance|
          id= 0
          File.open(absolute_path) do |file|
            file= StudioApi::File.upload(file, appliance.id, file_params)
            id= file.id.to_i
          end
          destination_file= initiate_file(file_dir, file_name, id)
          [destination_file]
        end
      end

      def show(file)
        if @not_local
          id= find_file_id(file)
          response= StudioApi::File.find(id)
          [ response.content ]
        else
          show_file(file)
        end
      end

      def diff(file)
        begin
          id= find_file_id(file)
          file_content= StudioApi::File.find(id).content
        rescue
          ["unable to connect"]
        end

        begin
          File.open('.tempfile', 'w') {|f| f.write(file_content)}
          diff= `diff .tempfile #{full_local_file_path(file)}`
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
