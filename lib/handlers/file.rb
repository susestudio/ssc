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
        file_params= ({:path => file_dir, :filename => file_name})
        file_params.merge!(optional_file_params)
        id= nil
        if options.remote?
          require_appliance do |appliance|
            File.open(absolute_path) do |file|
              file= StudioApi::File.upload(file, appliance.id, file_params)
              id= file.id.to_i
            end
            say "Overlay file saved. Id: #{id}"
          end
        end
        if ApplianceDirectory.new.valid?
          local_copy= FileListFile.new.initiate_file(absolute_path, file_params)
          say "Created #{local_copy}"
        end
      end

      desc 'file remove FILE_NAME', 'removes existing overlay file'
      require_appliance_id
      allow_remote_option
      def remove(file_name)
        file_list= FileListFile.new
        file_id= file_list.is_uploaded?(file_name)
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
          file_list.push('remove', {file_name => nil})
          file_list.save
          say "File '#{file_name}' marked for removal"
        end
      end

      desc 'file show FILE_NAME', 'show the contents of the file'
      require_appliance_id
      allow_remote_option
      method_option :file_id, :type => :string
      def show(file_name)
        if options.remote?
          begin
            require_appliance_directory do |appliance, files|
              id= files[:file_list].is_uploaded?(file_name)
              if id
                response= StudioApi::File.find(id)
                say response.content
              else
                say "File hasn't been uploaded.\nLocal Copy:", :red
                say ApplianceDirectory.show_file(File.join('files',file_name))
              end
            end
          rescue ApplianceDirectoryError
            if options.file_id
              say StudioApi::File.find(options.file_id).content
            else
              files= StudioApi::File.find(:all)
              files= files.select {|f| f.filename == file_name}
              raise Thor::Error, "File not found or ambiguous file name " unless files.length == 1
              say files[0].content
            end
          end
        else
          say ApplianceDirectory.show_file(File.join('files', file_name))
        end
      end

      desc 'file diff FILE_NAME', 'show the diff of the remote file and the local one'
      require_appliance_id
      def diff(file_name)
        require_appliance_directory do |appliance, files|
          id= files[:file_list].is_uploaded?(file_name)
          raise Thor::Error, "File hasn't been uploaded" unless id
          response= StudioApi::File.find(id)
          remote_content= response.content
          local_file= File.join(Dir.pwd, 'files', file_name)
          tempfile=Tempfile.new('ssc_file') 
          tempfile.write(remote_content)
          say find_diff(tempfile.path, local_file)
          tempfile.close; tempfile.unlink
        end
      rescue ApplianceDirectoryError
        raise Thor::Error, "diff can only be performed in the appliance directory"
      end

      desc 'file list', 'show all overlay files'
      require_appliance_id
      allow_remote_option
      def list
        require_appliance_directory do |appliance, files|
          file_list= files[:file_list]
          out= if options.remote? || file_list.empty_list?
            response= StudioApi::File.find(:all, :params => {:appliance_id => appliance.id})
            response= response.collect do |file|
              item= {file.filename => {"id" => file.id, "path" => file.path}}
              file_list.push('list', item)
            end
            file_list.save
            response
          else
            file_list["list"]
          end
          say out.to_yaml if @_invocations[SSC::Client] == ["file"]
        end
      rescue ApplianceDirectoryError
        require_appliance do |appliance|
          print_table StudioApi::File.find(:all, :params => {:appliance_id => appliance.id}).collect do |file|
            [file.id, File.join(file.path, file.filename)]
          end
        end
      end

      private

      def get_file_list(appliance_id)
      end

      def find_diff(file1, file2)
        `diff #{file1} #{file2}`
      rescue Errno::ENOENT
        raise Thor::Error, "'diff' not installed"
      end
    end
  end
end
