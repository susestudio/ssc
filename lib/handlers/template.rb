module SSC
  module Handler
    class Template < Base

      desc 'template list_sets', 'list all available template sets'
      require_authorization
      def list_sets
        templates= get_templates
        say_array templates.collect {|template| template.name}
      end

      desc 'template list SET_NAME', 'show details of a particular template set'
      require_authorization
      def list(name)
        template_set= get_templates.select{|t| t.name == name}[0]

        if template_set.nil?
          say "Template set called '#{name}' was not found."
        else
          out = [template_set.name+' : '+template_set.description]
          out += template_set.template.collect do |appliance| 
            "#{appliance.appliance_id}: #{appliance.name}"
          end
          say_array out
        end
      end
      
    private

      def get_templates
        StudioApi::TemplateSet.find(:all)
      end
    end
  end

end
