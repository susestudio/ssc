module SSC
  module Handler
    class Template

      include Helper

      def initialize(options= {})
        authorize(options['username'], options['password'])
      end
      
      def list
        templates= StudioApi::TemplateSet.find(:all)
        templates.each do |template|
          puts "#{template.id}: #{template.name}"
        end
      end
    end
  end

end
