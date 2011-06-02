require 'helper'

class TestHandlerAppliance < Test::Unit::TestCase
  context "SSC::Handler::Template" do
    context "#list" do
      setup do
        @handler= SSC::Handler::Appliance.new()
        @handler.stubs(:connect)
      end

      should "call find(:all) on StudioApi::Appliance" do
        mock_app_list= mock('appliance list')
        mock_app_list.stubs(:collect)
        mock_app_list.stubs(:empty?)
        StudioApi::Appliance.expects(:find).with(:all).returns(mock_app_list)
        @handler.list
      end
    end
  end
end
