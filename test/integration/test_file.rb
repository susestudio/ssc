require 'helper'

class TestOverlayFile < Test::Unit::TestCase
  context "file" do
    setup do
      @client= SSC::Client.new
      @auth_params= {:username => 'user', :password => 'pass'}
      @appliance_params= @auth_params.merge(:appliance_id => 5678)
      @default_mock_appliance= StudioApi::Appliance.new(:id => 5678, :name => 'test_appliance', :description => 'test description')
      StudioApi::Appliance.stubs(:clone).returns(@default_mock_appliance)
      @client.invoke('s_s_c:handler:appliance:create', ['test_appliance'], {:source_id => 1234}.merge(@auth_params))
      @default_mock_package= StudioApi::Package.new('test_package', :version => '1', :repository_id => 9876)
      StudioApi::Appliance.stubs(:find).with(5678).returns(@default_mock_appliance)
    end
    context "add" do
      setup do
        @test_file_path= File.join(ENV["HOME"], '.test_file.config')
        FileUtils.touch(@test_file_path)
      end
      context "when in the appliance directory" do
        setup do
          Dir.chdir('test_appliance') if Dir.exists?('test_appliance')
        end
        context "when the remote flag is set" do
          should "upload file and create a new file locally" do
            StudioApi::File.expects(:upload).returns(stub(:id => 1))
            mock_file_list= mock()
            SSC::DirectoryManager::FileListFile.stubs(:new).returns(mock_file_list)
            mock_file_list.expects(:initiate_file).with(@test_file_path, anything)
            @client.invoke('s_s_c:handler:overlay_file:add', [@test_file_path], {:remote => true, :appliance_id => 5678})
          end
        end
        context "when the remote flag is not set" do
          should "just add the file to the file_list in the add section" do
            mock_file_list= mock()
            SSC::DirectoryManager::FileListFile.stubs(:new).returns(mock_file_list)
            mock_file_list.expects(:initiate_file).with(@test_file_path, anything)
            @client.invoke('s_s_c:handler:overlay_file:add', [@test_file_path], {:appliance_id => 5678})
          end
        end
      end
      context "when not in the appliance directory" do
        setup do
          Dir.chdir('..') if File.exist?('./.sscrc')
          SSC::DirectoryManager::ApplianceDirectory.any_instance.stubs(:valid).returns(false)
        end
        context "when the remote flag is set" do
          should "just upload the file" do
            StudioApi::File.expects(:upload).returns(stub(:id => 1))
            @client.invoke('s_s_c:handler:overlay_file:add', [@test_file_path], {:appliance_id => 5678, :remote => true})
          end
        end
      end
    end

    context "remove" do
      context "when the remote flag is set" do
        should "destroy the file remotely" do
          SSC::DirectoryManager::FileListFile.any_instance.stubs(:is_uploaded?).returns(:id)
          mock_file_object= mock()
          mock_file_object.expects(:destroy)
          StudioApi::File.expects(:find).with(:id).returns(mock_file_object)
          @client.invoke('s_s_c:handler:overlay_file:remove', ["test_file"], {:remote => true})
        end
      end

      context "when the remote flag is not set" do
        should "add the filename to the remove list in file_list" do
          mock_file_list= mock()
          mock_file_list.stubs(:is_uploaded?).returns(:id)
          mock_file_list.expects(:push).with('remove', has_key('test_file'))
          mock_file_list.expects(:save)
          SSC::DirectoryManager::FileListFile.stubs(:new).returns(mock_file_list)
          @client.invoke('s_s_c:handler:overlay_file:remove', ["test_file"], {})
        end
      end
    end
  end


  def teardown
    Dir.chdir("..") unless Dir.exists?('test_appliance')
    FileUtils.rm_r('test_appliance')
    FileUtils.rm @test_file_path if @test_file_path && File.exists?(@test_file_path)
  end
end
