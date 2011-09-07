require 'helper'

class TestRepository < Test::Unit::TestCase

  context "repository" do
    setup do
      @client= SSC::Client.new
      @auth_params= {:username => 'user', :password => 'pass'}
      @appliance_params= @auth_params.merge(:appliance_id => 5678)
      @default_mock_appliance= StudioApi::Appliance.new(:id => 5678, :name => 'test_appliance', :description => 'test description')
      StudioApi::Appliance.stubs(:find).with(5678).returns(@default_mock_appliance)
      StudioApi::Appliance.stubs(:clone).returns(@default_mock_appliance)
      @client.invoke('s_s_c:handler:appliance:create', ['test_appliance'], {:source_id => 1234}.merge(@auth_params))
      Dir.chdir('test_appliance') if Dir.exists?('test_appliance')
      @default_mock_repo= StudioApi::Repository.new(:id => 3070, 
                                    :base_url => 'http://ftp.suse.de/repo/path',
                                    :base_system => '11.3',
                                    :name => 'test_repo', 
                                    :type => 'rpm-md') 
    end

    context "search" do
      setup do
        @default_mock_repo.stubs(:matches).returns(stub(:attributes => ''))
        StudioApi::Repository.expects(:find).with(:all, has_entry(:params, {:filter => 'search_string'})).returns([@default_mock_repo])
      end
      should "search all repos" do
        @client.invoke('s_s_c:handler:repository:search', ['search_string'], @auth_params)
      end
    end

    context "list" do
      context "when remote option is on" do
        setup do
          @default_mock_appliance.expects(:repositories).returns([@default_mock_repo])
        end
        should "list all repositories in the appliance" do
          @client.invoke('s_s_c:handler:repository:list', [], @appliance_params)
        end
      end
    end

    ["add", "remove"].each do |action|
      context action do
        context "when the remote flag is on" do
          should "make the '#{ action }' on studio" do
            @default_mock_appliance.expects("#{action}_repository".to_sym).with([ 3070 ]).returns(stub(:collect=> [""]))
            @client.invoke("s_s_c:handler:repository:#{action}", [3070], @appliance_params.merge(:remote => true))
          end
        end
        context "when the remote flag is off" do
          context "when in the appliance directory" do
            should "make the '#{action}' in the repository file" do
              @client.invoke("s_s_c:handler:repository:#{action}", ['test_repository'], @appliance_params.merge(:remote =>false))
              file= File.join(Dir.pwd, 'repositories')
              assert YAML::load(File.read(file))[action].include?('test_repository')
            end
          end
          context "when outside of the appliance directory" do
            setup do
              Dir.chdir('..')
            end
            should "raise and error" do
              assert_raise(Errno::ENOENT) do 
                @client.invoke("s_s_c:handler:repository:#{action}", ['test_repository'], @appliance_params.merge(:remote =>false))
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
