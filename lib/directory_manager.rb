module SSC
  module DirectoryManager

    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def create_appliance_directory(appliance_dir, username, password, appliance_id)
        FileUtils.mkdir_p(appliance_dir)
        FileUtils.mkdir_p(File.join(appliance_dir, 'files'))
        FileUtils.touch(File.join(appliance_dir, 'repositories'))
        FileUtils.touch(File.join(appliance_dir, 'software'))
        FileUtils.touch(File.join(appliance_dir, 'files/.file_list'))
        File.open(File.join(appliance_dir, '.sscrc'), 'w') do |file|
          file.write("username: #{username}\n"+
                     "password: #{password}\n"+
                     "appliance_id: #{appliance_id}")
        end
        File.join(Dir.pwd, appliance_dir)
      end

      def manage(local_source)
        self.class.class_variable_set('@@appliance_directory', Dir.pwd)
        if appliance_directory_valid?(Dir.pwd)
          file= File.join(Dir.pwd, local_source)
          self.class.class_variable_set('@@local_source', file) if File.exist?(file)
        end
      end

      private

      def appliance_directory_valid?(dir)
        config_file= File.join(dir, '.sscrc')
        File.exist?(config_file) && File.read(config_file).match(/appliance_id:\ *\d+/)
      end

    end

    module InstanceMethods

      # Save data to local storage file
      # @param [String] section The section of the document that is to be saved
      # @param [Array] list The data in Array format which will be merged with existing data
      def save(section, list)
        safe_get_source_file do |source|
	  parsed_file= YAML::load(File.read(source))
          # YAML::load returns false if file is empty
          parsed_file= {} unless parsed_file
          final_list= list
          if parsed_file[section]
            current_list= parsed_file[section]
            final_list= current_list | final_list
          end
          parsed_file[section]= final_list
          File.open(source, 'w') {|f| f.write parsed_file.to_yaml}
        end
      end

      # Reads data from the local storage file
      # @param [String] section (optional) This is the top-level section
      #	  of the storage file that is to be read. It can be left blank to 
      #	  return all sections of the file
      #	@return [String] Either the whole file of the specified section
      def read(section = nil)
        safe_get_source_file do |source|
	  if section
	    parsed_file= YAML::load(File.read(source))
	    parsed_file[section]
	  else
	    File.read(source)
	  end
        end
      end

      private


      # Wrapper to check existence of source file and other sanity checks 
      # It takes a block with one argument - the path of the source file
      def safe_get_source_file
        source= self.class.class_variable_get('@@local_source')
        source= File.join(Dir.pwd, source)
        if File.exist?(source)
          yield source
        else
          raise "Couldn't find the local source file" unless options.remote?
        end
      end

      def find_file_id(file_name) 
        file_list= File.join(self.class.class_variable_get('@@local_source'), '.file_list')
        parsed_file= YAML::load(File.read(file_list))
        if parsed_file["file_name"]
          id= parsed_file["file_name"]["id"] 
        else
          raise ArgumentError, "file not found"
        end
      end

      def full_local_file_path(file)
        full_path= File.join(self.class.class_variable_get('@@local_source'), file)
      end

      def show_file(file)
        full_path= full_local_file_path(file)
        if File.exist?(full_path)
          File.read(full_path)
        else
          raise ArgumentError, "file not found"
        end
      end

      def initiate_file(file_dir, file_name, id)
        source_file= File.join(file_dir, file_name)
        destination_file= full_local_file_path(file_name)
        if File.exist?(source_file)
          FileUtils.cp(source_file, destination_file)
          File.open(File.join(source, '.file_list'), 'a+') do  |f|
            file_entry= "\n#{destination_file}\n  source_dir: #{file_dir}\n  id: #{id}"
            write_to_file(f, [file_entry])
          end
          destination_file
        else
          raise ArgumentError, "File does not exist"
        end
      end

      def list_local_files
        source= self.class.class_variable_get('@@local_source')
        File.readlines(File.join(source, '.file_list')).collect{|i| i.strip} if source
      end

      def parse_file_list
        source= self.class.class_variable_get('@@local_source')
        file_list= File.read(File.join(source, '.file_list'))
        YAML::load(file_list)
      end

      def write_to_file(file, data)
        written= []
        existing_lines= file.readlines.collect{|i| i.strip}
        file.write("\n") if existing_lines.last != '' and existing_lines != []
        data.each do |line|
          unless existing_lines.include?( line )
            file.write(line+"\n") 
            written << line
          end
        end
      end

      # Checks if the local source file has a list 
      # local_empty? is deprecated and is to be replaced with no_local_list?
      # @return [Boolean] true if there is no list
      def local_empty?
        safe_get_source_file do |source|
          list= YAML::load(File.read source)
          !list || list == nil || list == {} || list == []
        end
      end
      
      alias :no_local_list? :local_empty?

    end
  end
end
