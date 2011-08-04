require 'tempfile'

module SSC
  module Handler
    class OverlayFile < Base

      include DirectoryManager

      no_tasks do
        cattr_reader :local_source
        @@local_source= 'files/'
      end

      desc 'file add PATH', 'create a new overlay file'
      require_appliance_id
      allow_remote_option
      method_option :path,        :type => :string, :default => ''
      method_option :name,        :type => :string, :default => ''
      method_option :permissions, :type => :string, :default => '0755'
      method_option :owner,       :type => :string, :default => 'root'
      method_option :group,       :type => :string, :default => 'root'
      def add(path)
        absolute_path= File.expand_path(path)
        optional_file_params= {:permissions => options.permissions, 
                               :group       => options.group,
                               :owner       => options.owner}
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
        local_copy= FileListFile.new.initiate_file(absolute_path, file_params)
        say "Created #{local_copy}"
      end

      desc 'file remove FILE_NAME', 'removes existing overlay file'
      require_appliance_id
      allow_remote_option
      def remove(file_name)
        @file_list= FileListFile.new
        file_id= @file_list.is_uploaded?(file_name)
        if options.remote? && file_id
          begin
            StudioApi::File.find(file_id).destroy
            say "File '#{file_name}' removed"
          rescue
            raise Thor::Error, "Couldn't remove file #{file_name} (id: #{file_id}"
          end
        elsif options.remote? && !file_id
          raise Thor::Error, "File '#{file_name}' not found"
        else
          @file_list.push('remove', {file_name => nil})
          @file_list.save
          say "File '#{file_name}' marked for removal"
        end
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
              {file.filename => {"id" => file.id, "path" => file.path}}
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
