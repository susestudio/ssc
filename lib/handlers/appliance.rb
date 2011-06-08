require 'fileutils'

module SSC
  module Handler
    class Appliance < Base

      def create(appliance_name)
        appliance_dir= File.join('.', appliance_name) 
        if @options[:source_id]
          params= {:name => appliance_name}
          params.merge!(:arch => @options[:arch]) if @options[:arch]
          appliance= StudioApi::Appliance.clone(@options[:source_id], params)
        else
          raise "--source_id is required"
        end
        FileUtils.mkdir(appliance_dir)
        FileUtils.mkdir(File.join(appliance_dir, 'files'))
        FileUtils.touch(File.join(appliance_dir, 'repositories'))
        FileUtils.touch(File.join(appliance_dir, 'software'))
        File.open(File.join(appliance_dir, '.sscrc'), 'w') do |file|
          file.write("username: #{@options[:username]}\n"+
                     "password: #{@options[:password]}\n"+
                     "appliance_id: #{appliance.id}")
        end
        ["Created: ", appliance_dir, 
         File.join(appliance_dir, 'files'),
         File.join(appliance_dir, 'repositories'),
         File.join(appliance_dir, 'software') ]
      end
      
      def list
        appliances= StudioApi::Appliance.find(:all)
        appliances.collect{|i| "#{i.id}: #{i.name}"}
      end

      def show(id)
        appliance= StudioApi::Appliance.find(id)
        ["#{appliance.id}: #{appliance.name}",
         "Parent: ( #{appliance.parent.id} ) #{appliance.parent.name}",
         "Download Url: #{download_url(appliance)}" ]
      end

      def repositories
        require_appliance_id(@options) do |appliance|
          appliance.repositories.collect do |repo|
            "#{repo.name}: #{repo.base_url}"
          end
        end
      end

      def installed_software
        require_appliance_id(@options) do |appliance|
          appliance.installed_software.collect do |software|
            "#{software.name} v#{software.version}"
          end
        end
      end

      def destroy
        require_appliance_id(@options) do |appliance|
          if appliance.destroy.code_type == Net::HTTPOK
            ['Appliance Successfully Destroyed']
          else
            ['There was a problem with destroying the appliance.',
             'Make sure that you\'re in the appliance directory OR',
             'Have provided the --appliance_id option']
          end
        end
      end

      private

      def download_url(appliance)
        if appliance.builds.empty?
          "No Build Yet"
        else
          appliance.builds.last.download_url
        end
      end
    end
  end
end
