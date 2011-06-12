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
      Dir.chdir('..')
      FileUtils.rm_r('test_dir')
    end

    should "extend and include properly" do
      assert_equal File.join(@app_dir, 'software'), A.class_variable_get('@@local_source')
    end

  end
end
