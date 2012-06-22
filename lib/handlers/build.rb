module SSC
  module Handler
    class Build < Base

      default_task :build

      desc "build", "Builds an appliance.\n\nAccepted image types: oem, iso, xen, vmx"
      require_appliance_id
      method_option :image_type, :type => :string, :default => "iso", :required => true
      def build
        require_appliance_directory do |appliance, files|
          if appliance.status.state != "ok"
            raise Thor::Error, "Appliance is not OK. Please fix before building.\n#{appliance.status.issues.join("\n")}\n"
          else
            build = StudioApi::RunningBuild.new(:appliance_id => appliance.id, :image_type => options.image_type, :force => true)
            build.save
            config_file= File.join(Dir.pwd, '.sscrc')
            if File.exists?(config_file)
              config= YAML::load(File.read(config_file))
              config.merge!('latest_build_id' => build.id)
              File.open(config_file, 'w') do |file|
                file.write(config.to_yaml)
              end
            end
            say "Build Started. Build id: #{build.id}"
          end
        end
      end

      desc "status", "find the build status of an appliance"
      require_authorization
      require_build_id
      def status
        build = StudioApi::RunningBuild.find options.build_id
        say "Build Status: #{build.state}"
        say "#{build.percent}% completed" if build.state == "running"
      end

      desc "list", "list builds (running or completed)"
      require_appliance_id
      method_option :running, :type => :boolean, :default => false
      def list
        builds= if options.running?
          StudioApi::RunningBuild.find(:all, :params => {:appliance_id => options.appliance_id})
        else
          StudioApi::Build.find(:all, :params => {:appliance_id => options.appliance_id})
        end
        
        say "Build List:\n"
        builds_info = builds.collect{ |i|
          [i.id, "v#{i.version}", i.state, format_download_url(i)]
        }
                    
        print_table([["id", "version", "state", "download link"]]+ builds_info)
      end

      private

      def format_download_url build
        if build.respond_to?(:download_url)
          build.download_url
        else
          "n\\a"
        end
      end
    end
  end
end
