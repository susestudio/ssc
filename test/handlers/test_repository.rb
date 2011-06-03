require 'helper'

class TestHandlerRepository < Test::Unit::TestCase
  context "SSC::Handler::Repository" do
    context "#search" do
      setup do
        @handler= SSC::Handler::Repository.new()
        @handler.stubs(:connect)
      end

      should "call .find(:all, params_hash) on StudioApi::Repository" do
        mock_collection= mock('collection')
        mock_collection.stubs(:collect)
        StudioApi::Repository.expects(:find).with(:all, :params => {:filter => 'chess', :base_system => '11.1'}).returns(mock_collection)
        @handler.instance_variable_set('@options', {:base_system => '11.1'})
        @handler.search('chess')
      end
    end
  end
end
