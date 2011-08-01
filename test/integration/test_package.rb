require 'helper'

class TestPackage < Test::Unit::TestCase

  context "package" do
    setup do
      @client= SSC::Client.new
      @auth_params= {:username => 'user', :password => 'pass'}
      @appliance_params= @auth_params.merge(:appliance_id => 5678)
      @default_mock_appliance= StudioApi::Appliance.new(:id => 5678, :name => 'test_appliance', :description => 'test description')
      StudioApi::Appliance.stubs(:clone).returns(@default_mock_appliance)
      @client.invoke('s_s_c:handler:appliance:create', ['test_appliance'], {:source_id => 1234}.merge(@auth_params))
      @default_mock_package= StudioApi::Package.new('test_package', :version => '1', :repository_id => 9876)
      StudioApi::Appliance.stubs(:find).with(5678).returns(@default_mock_appliance)
      Dir.chdir('test_appliance') if Dir.exists?('test_appliance')
    end

    context "search" do
      setup do
        @default_mock_appliance.expects(:search_software).returns([@default_mock_package])
      end
      should "search all repos" do
        @client.invoke('s_s_c:handler:package:search', ['search_string'], @appliance_params.merge(:all_repos => false))
      end
    end

    context "list" do
      ["selected", "installed"].each do |type|
        context type do
          setup do
            @default_mock_appliance.expects("#{type}_software".to_sym).returns([@default_mock_package])
          end
          should "list all #{type} packages and patterns in the appliance" do
            @client.invoke('s_s_c:handler:package:list', [type], @appliance_params)
          end
        end
      end
    end

    ["add", "remove", "ban", "unban"].each do |action|
      context action do
        context "when the remote flag is on" do
          should "make the '#{ action }' on studio" do
            @default_mock_appliance.expects("#{action}_package".to_sym).with('test_package').returns({'state' => 'fixed'})
            @client.invoke("s_s_c:handler:package:#{action}", ['test_package'], @appliance_params.merge(:remote => true))
          end
        end
        context "when the remote flag is off" do
          context "when in the appliance directory" do
            should "make the '#{action}' in the package file" do
              @client.invoke("s_s_c:handler:package:#{action}", ['test_package'], @appliance_params.merge(:remote =>false))
              file= File.join(Dir.pwd, 'software')
              assert YAML::load(File.read(file))[action].include?('test_package')
            end
          end
          context "when outside of the appliance directory" do
            setup do
              Dir.chdir('..')
            end
            should "raise and error" do
              assert_raise(Errno::ENOENT) do 
                @client.invoke("s_s_c:handler:package:#{action}", ['test_package'], @appliance_params.merge(:remote =>false))
              end
            end
          end
        end
      end
    end
  end

  def teardown
    Dir.chdir("..") unless Dir.exists?('test_appliance')
    FileUtils.rm_r('test_appliance')
  end
end
