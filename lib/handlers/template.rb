module SSC
  module Handler
    class Template < Base

      desc 'list', 'list all available template sets'
      require_authorization
      def list
        templates= StudioApi::TemplateSet.find(:all)
        say_array templates.collect {|template| template.name}
      end

      desc 'show NAME', 'show details of a particular template set'
      require_authorization
      def show(name)
        template_set= StudioApi::TemplateSet.find(name)
        out = [template_set.name+' : '+template_set.description]
        out += template_set.template.collect do |appliance| 
          "#{appliance.appliance_id}: #{appliance.name}"
        end
        say_array out
      end
    end
  end

end
