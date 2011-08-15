require 'helper'

class TestOverlayFile < Test::Unit::TestCase

  include SSC::DirectoryManager

  context "file" do
    setup do
      @client= SSC::Client.new
      @auth_params= {:username => 'user', :password => 'pass'}
      @appliance_params= @auth_params.merge(:appliance_id => 5678)
      @default_mock_appliance= StudioApi::Appliance.new(:id => 5678, :name => 'test_appliance', :description => 'test description')
      StudioApi::Appliance.stubs(:clone).returns(@default_mock_appliance)
      @client.invoke('s_s_c:handler:appliance:create', ['test_appliance'], {:source_id => 1234}.merge(@auth_params))
      @default_mock_package= StudioApi::Package.new('test_package', :version => '1', :repository_id => 9876)
      StudioApi::Appliance.stubs(:find).returns(@default_mock_appliance)
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
            FileListFile.stubs(:new).returns(mock_file_list)
            mock_file_list.expects(:initiate_file).with(@test_file_path, anything)
            @client.invoke('s_s_c:handler:overlay_file:add', [@test_file_path], {:remote => true, :appliance_id => 5678})
          end
        end
        context "when the remote flag is not set" do
          should "just add the file to the file_list in the add section" do
            mock_file_list= mock()
            FileListFile.stubs(:new).returns(mock_file_list)
            mock_file_list.expects(:initiate_file).with(@test_file_path, anything)
            @client.invoke('s_s_c:handler:overlay_file:add', [@test_file_path], {:appliance_id => 5678})
          end
        end
      end
      context "when not in the appliance directory" do
        setup do
          Dir.chdir('..') if File.exist?('./.sscrc')
          ApplianceDirectory.any_instance.stubs(:valid).returns(false)
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
          FileListFile.any_instance.stubs(:is_uploaded?).returns(:id)
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
          FileListFile.stubs(:new).returns(mock_file_list)
          @client.invoke('s_s_c:handler:overlay_file:remove', ["test_file"], {})
        end
      end
    end
    context "show" do
      context "when not in the appliance directory" do
        setup do
          Dir.chdir('..') if File.exists?('.sscrc')
        end
        context "and when the remote flag is set with the file_id option" do
          should "show the file using the file_id" do
            StudioApi::File.expects(:find).with(1).returns(stub(:content => ''))
            @client.invoke('s_s_c:handler:overlay_file:show', ['test_file'], @appliance_params.merge({:remote => true, :file_id => 1}))
          end
        end
        context "and when the remote flag is set without the file_id option" do
          should "show the file using the file_name" do
            StudioApi::File.expects(:find).with(:all).returns([stub(:content => '', :filename => 'test_file')])
            @client.invoke('s_s_c:handler:overlay_file:show', ['test_file'], @appliance_params.merge({:remote => true}))
          end
        end
      end
      context "when in the appliance directory" do
        setup do
          Dir.chdir('test_appliance') if Dir.exists?('test_appliance')
        end
        context "and when the remote flag is set" do
          should "show the file if file has been uploaded" do
            FileListFile.any_instance.stubs(:is_uploaded?).returns(:id)
            StudioApi::File.expects(:find).with(:id).returns(stub(:content => ''))
            @client.invoke('s_s_c:handler:overlay_file:show', ['test_file'], @appliance_params.merge({:remote => true}))
          end

          should "show the local file if the file hasn't been uploaded" do
            FileListFile.any_instance.stubs(:is_uploaded?).returns(nil)
            ApplianceDirectory.expects(:show_file).with('files/test_file')
            @client.invoke('s_s_c:handler:overlay_file:show', ['test_file'], @appliance_params.merge({:remote => true}))
          end
        end
      end
    end

    context "diff" do
      context "when in the appliance directory" do
        setup do
          Dir.chdir('test_appliance') if Dir.exists?('test_appliance')
          File.open('files/test_file', 'w') {|f| f.write('test')}
        end
        should "show the diff of the two files" do
          FileListFile.any_instance.expects(:is_uploaded?).returns(:id)
          StudioApi::File.expects(:find).with(:id).returns(stub(:content => ''))
          @client.invoke('s_s_c:handler:overlay_file:diff', ['test_file'], @appliance_params)
        end
      end
    end

    context "list" do
      context "when in an appliance directory" do
        setup do
          Dir.chdir('test_appliance') if Dir.exists?('test_appliance')
        end
        should "list the files and save to the file list file" do
          FileListFile.any_instance.stubs(:empty_list? => true, :push => {}, :[] => {})
          mock_file= StudioApi::File.new(:path => 'path', :id => 1, 
                                         :filename => 'filename')
          StudioApi::File.expects(:find).with(:all, anything).returns([mock_file])
          @client.invoke('s_s_c:handler:overlay_file:list', [], @appliance_params)
        end
      end
      context "when not in an appliance directory" do
      end
    end
  end


  def teardown
    Dir.chdir("..") unless Dir.exists?('test_appliance')
    FileUtils.rm_r('test_appliance')
    FileUtils.rm @test_file_path if @test_file_path && File.exists?(@test_file_path)
  end
end
