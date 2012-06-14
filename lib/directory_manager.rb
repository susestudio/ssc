module SSC
  module DirectoryManager
    class LocalStorageFile

      def initialize(file_name, path= nil)
        path = path ? path : Dir.pwd
        @location= File.join(path, file_name)
      end

      def valid?
        File.exist?(@location)
      end

      def read
        # default error is informative enough if the file is not found
        @parsed_file = @parsed_file || YAML::load(File.read(@location)) || {}
      end

      def [](section)
        read
        if @parsed_file[section]
          @parsed_file[section]
        else
          []
        end
      end

      def pop(section)
        read
        if @parsed_file[section].is_a?(Array)
          @parsed_file[section].pop
        else
          nil
        end
      end
      
      def push(section, item)
        clean
        read
        if @parsed_file[section].is_a?(Array)
          @parsed_file[section] |= [ item ]
        else
          @parsed_file[section] = [ item ]
        end
        item
      end


      def save
        contents= @parsed_file.to_yaml
        @parsed_file= nil
        File.open(@location, 'w') {|f| f.write contents}
        contents
      end

      def empty_list?
        read
        (!@parsed_file['list']) || (@parsed_file['list'] == []) || (@parsed_file['list'] == {})
      end

      def clean
        File.open(@location, 'w') {}
      end
    end

    class PackageFile < LocalStorageFile
      def initialize(path= nil)
        super("software", path)
      end
    end

    class RepositoryFile < LocalStorageFile
      def initialize(path= nil)
        super("repositories", path)
      end
    end

    class FileListFile < LocalStorageFile
      def initialize(path= nil)
        super("files/.file_list", path)
      end

      def pop(section)
        file_hash= super(section)
        if file_hash
          file_name= file_hash.keys[0]
          file_hash= file_hash[file_name]
          { :name      => file_name,
            :full_path => File.join(file_hash["path"]),
            :params    => file_hash.slice("owner", "group", "permissions")}
        end
      end

      def initiate_file(path, options)
        raise "Unknown file #{path}" unless File.exists?(path)
        file_path, file_name= File.split(path)
        file_path ||= options[:path]
        destination_path= File.join(File.split(@location)[0], file_name)
        FileUtils.cp(path, destination_path)
        if options[:id]
          push("list", {file_name => {
            "id" => options[:id],
            "path" => file_path }})
        else
          file_params= options.slice(:permissions, :group, :owner).merge(:path => file_path)
          push("add", {file_name => file_params})
        end
        destination_path
      end

      def is_uploaded?(file_name)
        read
        list= @parsed_file["list"].select{|i| i.keys[0] == file_name}
        list[0][file_name]["id"] if list.length > 0 
      end

    end

    class ApplianceDirectory
      attr_reader :path
      attr_reader :files

      def initialize(name= '', options = {})
        @name= name
        @path= File.join(Dir.pwd, name)
        @files = if Dir.exist?(@path)
                   {:package   => PackageFile.new(@path),
                   :repository => RepositoryFile.new(@path),
                   :file_list  => FileListFile.new(@path)}
                 else
                   {}
                 end
        @options= options
      end

      def create
        FileUtils.mkdir_p(@name)
        FileUtils.mkdir_p(File.join(@name, 'files'))
        @files[:repository] = FileUtils.touch(File.join(@name, 'repositories'))[0]
        @files[:package]    = FileUtils.touch(File.join(@name, 'software'))[0]
        @files[:file_list]  = FileUtils.touch(File.join(@name, 'files/.file_list'))[0]
        File.open(File.join(@name, '.sscrc'), 'w') do |file|
          file.write(@options.stringify_keys.to_yaml)
        end
        File.join(Dir.pwd, @name)
      end

      def valid?
        Dir.exists?(@path) && File.exists?(File.join(@path, '.sscrc'))
      end

      class << self
        def show_file(relative_path)
          path= File.join(@path, relative_path)
          File.read(path)
        end
      end
    end
  end
end
