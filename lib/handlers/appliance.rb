module SSC
  module Handler
    class Appliance < Base

      desc "create APPLIANCE_NAME", "Create an appliance"
      require_authorization
      method_option :source_id, :type => :numeric, :required => true
      method_option :arch, :type => :string
      def create(appliance_name)
        appliance_dir= File.join('.', appliance_name) 
        params= {:name => appliance_name}
        params.merge!(:arch => options.arch) if @options[:arch]
        appliance= StudioApi::Appliance.clone(options.source_id, params)
        appliance_dir= self.class.create_appliance_directory(appliance_dir, options.username, options.password, appliance.id)
        ["Created: ", appliance_dir, 
         File.join(appliance_dir, 'files'),
         File.join(appliance_dir, 'repositories'),
         File.join(appliance_dir, 'software') ]
      end
      
      #def list
        #appliances= StudioApi::Appliance.find(:all)
        #appliances.collect{|i| "#{i.id}: #{i.name}"}
      #end

      #def show(id)
        #appliance= StudioApi::Appliance.find(id)
        #["#{appliance.id}: #{appliance.name}",
         #"Parent: ( #{appliance.parent.id} ) #{appliance.parent.name}",
         #"Download Url: #{download_url(appliance)}" ]
      #end

      #def destroy
        #require_appliance_id(@options) do |appliance|
          #if appliance.destroy.code_type == Net::HTTPOK
            #['Appliance Successfully Destroyed']
          #else
            #['There was a problem with destroying the appliance.',
             #'Make sure that you\'re in the appliance directory OR',
             #'Have provided the --appliance_id option']
          #end
        #end
      #end

      #def status
        #require_appliance_id(@options) do |appliance|
          #response= appliance.status
          #case response.state
          #when 'error'
            #["Error: #{response.issues.issue.text}"]
          #when 'ok'
            #["Appliance Ok"]
          #end
        #end
      #end

      #private

      #def download_url(appliance)
        #if appliance.builds.empty?
          #"No Build Yet"
        #else
          #appliance.builds.last.download_url
        #end
      #end
    end
  end
end
