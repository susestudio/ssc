require 'helper'

class TestTemplateHandler < Test::Unit::TestCase
  context "SSC::Handler::Template" do
    context "#list" do
      setup do
        @handler= SSC::Handler::Template.new()
        @handler.stubs(:authorize)
      end

      should "call .find(:all) on StudioApi::TemplateSet" do
        mock_template= mock('template_list')
        mock_template.stubs(:each)
        StudioApi::TemplateSet.expects(:find).with(:all).returns(mock_template)
        @handler.list
      end
    end
  end
end
