module SSC
  module Handler
    class Build < Base

      default_task :build

      desc "build", "build an appliance"
      require_appliance_id
      method_option :image_type, :type => :string, :required => true
      def build
        require_appliance_directory do |appliance, files|
          if appliance.status.state != "ok"
            raise Thor::Error, "Appliance is not OK. Please fix before building.\n#{appliance.status.issues.join("\n")}\n"
          else
            build = StudioApi::RunningBuild.new(:appliance_id => appliance.id, :image_type => options.image_type)
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
        build = StudioApi::Build.find options.build_id
        additional_info=(build.state == 'finished' ? "" : " - #{build.percent}")
        say "Build Status: #{build.state}" + additional_info
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
        print_table([["id", "version", "state"]]+
                    builds.collect{|i| [i.id, "v#{i.version}", i.state]})
      end


    end
  end
end
