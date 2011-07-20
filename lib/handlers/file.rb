require 'tempfile'

module SSC
  module Handler
    class OverlayFile < Base


      no_tasks do
        cattr_reader :local_source
        @@local_source= 'files/'
      end

      # must be run in appliance directory
      # takes the following argument:
      # file_path => (relative positions("." and "..") allowed and ~ for home directory allowed)
      # takes the following options:
      # --path="/path/to/file_directory/"   => optional (by default it is the path of the file on the local system)
      # --name="file_name"                  => optional (by default it is the name of the file on the local system)
      # --permissions="0766"                => optional (default: 0755)
      # --owner="user"                      => optional (default: root)
      desc 'file create PATH', 'create a new overlay file'
      require_appliance_id
      allow_remote_option
      method_option :path, :type => :string, :default => ''
      method_option :name, :type => :string, :default => ''
      method_option :permissions, :type => :string, :default => '0755'
      method_option :owner, :type => :string, :default => 'root'
      def create(path)
        absolute_path= File.expand_path(path)
        optional_file_params= {:permissions => options.permissions, 
                               :owner => options.owner}
        file_dir, file_name= File.split(absolute_path)
        file_dir = options.path == '' ? file_dir : options.path
        file_name = options.name == '' ? file_name : options.name
        id= nil
        if options.remote?
          require_appliance do |appliance|
            file_params= ({:path => file_dir, :filename => file_name})
            file_params.merge!(optional_file_params)
            File.open(absolute_path) do |file|
              file= StudioApi::File.upload(file, appliance.id, file_params)
              id= file.id.to_i
            end
            say "Overlay file saved. Id: #{id}"
          end
        end
        local_copy= initiate_file(file_dir, file_name, id)
        say "Created #{local_copy}"
      end

      desc 'file show FILE_NAME', 'show the contents of the file'
      require_appliance_id
      allow_remote_option
      def show(file_name)
        if options.remote?
          id= find_file_id(file_name)
          response= StudioApi::File.find(id)
          say response.content
        else
          say show_file(file_name)
        end
      end

      desc 'file diff FILE_NAME', 'show the diff of the remote file and the local one'
      require_appliance_id
      def diff(file_name)
        begin
          id= find_file_id(file_name)
          file_content= StudioApi::File.find(id).content
        rescue
          say "unable to connect or not in appliance directory", :red
        end

        begin
          tempfile=Tempfile.new('ssc_file') 
          tempfile.write(file_content)
          say find_diff(tempfile.path, full_local_file_path(file_name))
          tempfile.close; tempfile.unlink
        rescue Errno::ENOENT
          say "diff not installed", :red
        end
      end

      desc 'file list', 'show all overlay files'
      require_appliance_id
      allow_remote_option
      def list
        require_appliance do |appliance|
          out= if options.remote? || file_list_empty?
            response= StudioApi::File.find(:all, :params => {:appliance_id => appliance.id})
            response.collect do |file|
              {file.filename => {"id" => id, "path" => file.path}}
            end
          else
            list_local_files
          end
          say out.to_yaml
        end
      end
    end
  end
end
