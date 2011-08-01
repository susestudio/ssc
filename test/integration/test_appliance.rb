require 'helper'

class TestAppliance < Test::Unit::TestCase
  context "appliance" do
    setup do
      @client= SSC::Client.new
      @auth_params= {:username => 'user', :password => 'pass'}
      @default_mock_appliance= StudioApi::Appliance.new(:id => 5678, :name => 'test_appliance', :description => 'test description')
    end
    context "create" do

      setup do
        StudioApi::Appliance.expects(:clone).with(1234, has_entry(:name=>'test_appliance')).returns(@default_mock_appliance)
        @client.invoke('s_s_c:handler:appliance:create', ['test_appliance'], {:source_id => 1234}.merge(@auth_params))
      end

      should "create an appliance directory" do
        @client.invoke('s_s_c:handler:appliance:create', ['test_appliance'], {:source_id => 1234}.merge(@auth_params))
        assert Dir.exists?('./test_appliance')
      end

      should "have the software, repository and file_list files" do
        @client.invoke('s_s_c:handler:appliance:create', ['test_appliance'], {:source_id => 1234}.merge(@auth_params))
        assert File.exists?("./test_appliance/software")
        assert File.exists?("./test_appliance/repositories")
        assert File.exists?("./test_appliance/files/.file_list")
      end
    end

    context "list" do
      setup do
        StudioApi::Appliance.expects(:find).with(:all).returns([@default_mock_appliance])
      end
      should "return a list of all user's appliances" do
        @client.invoke('s_s_c:handler:appliance:list', [], @auth_params)
      end
    end

    context "info" do
      setup do
        appliance= @default_mock_appliance.clone
        parent_mock= @default_mock_appliance.clone
        builds_mock= []
        appliance.expects(:parent).twice.returns(parent_mock)
        appliance.expects(:builds).returns(builds_mock)
        StudioApi::Appliance.expects(:find).with(5678).returns(appliance)
      end
      should "display information on a given appliance" do
        @client.invoke('s_s_c:handler:appliance:info', [], @auth_params.merge({:appliance_id => 5678}))
      end
    end

    context "destroy" do
      setup do
        appliance= @default_mock_appliance.clone
        appliance.expects(:destroy).returns(stub(:code_type => Net::HTTPOK))
        StudioApi::Appliance.expects(:find).with(5678).returns(appliance)
      end

      should "destroy the appliance" do
        @client.invoke('s_s_c:handler:appliance:destroy', [], @auth_params.merge({:appliance_id => 5678}))
      end
    end

    context "status" do
      setup do
        appliance= @default_mock_appliance.clone
        status= mock(); status.expects(:state).returns('ok')
        appliance.expects(:status).returns(status)
        StudioApi::Appliance.expects(:find).with(5678).returns(appliance)
      end

      should "give the status of the appliance" do
        @client.invoke('s_s_c:handler:appliance:status', [], @auth_params.merge({:appliance_id => 5678}))
      end
    end
  end

  def teardown
    FileUtils.rmdir('test_appliance')
  end
end
