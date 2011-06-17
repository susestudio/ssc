require 'helper'
require 'fileutils'

class TestDirectoryManager < Test::Unit::TestCase
  context "SSC::DirectoryManager" do
    setup do
      class B; include SSC::DirectoryManager; end
      @app_dir= B.create_appliance_directory('test_dir','user','pass',1)
      Dir.chdir('test_dir')
      class A
        include SSC::DirectoryManager
        manage 'software'
      end
    end

    should "set the @@local_source variable correctly" do
      assert_equal File.join(@app_dir, 'software'), A.class_variable_get('@@local_source')
    end

    context "#save" do
      should "save data to the local cache file"  do
        A.new.save(['some', 'data'])
        assert_equal "some\ndata\n", File.read('software')
      end
    end

    context "#read" do
      should "fetch data from local_source" do
        A.new.save(['some', 'data'])
        assert_equal ['some', 'data'], A.new.read
      end
    end

  end

  def teardown
    Dir.chdir('..')
    FileUtils.rm_r('test_dir')
  end
end
