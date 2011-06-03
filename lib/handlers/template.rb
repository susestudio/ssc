module SSC
  module Handler
    class Template < Base

      def list
        templates= StudioApi::TemplateSet.find(:all)
        templates.collect {|template| template.name}
      end

      def show(name)
        template_set= StudioApi::TemplateSet.find(name)
        out = [template_set.name+' : '+template_set.description]
        out += template_set.template.collect do |appliance| 
          "#{appliance.appliance_id}: #{appliance.name}"
        end
      end
    end
  end

end
