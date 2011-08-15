require 'helper'

class TestFileListFile < Test::Unit::TestCase
  include SSC::DirectoryManager
  
  def setup
    @file_list_file= FileListFile.new
    @data = {"list"   => [{'file2' => {'path' => '/file/path'}},
                          {'file1' => {'id'    => 1, 
                                       'path'  => '/file/path',
                                       'owner' => 'root',
                                       'group' => 'root' }}],
             "add"    => [],
             "remove" => []}
    @file_list_file.instance_variable_set('@parsed_file', @data)
  end

  context "#pop" do
    should "reformat the file list hash" do
      assert_equal({:name=>"file1", :full_path=>"/file/path", 
                    :params=>{"owner"=>"root", "group"=>"root"}}, 
                   @file_list_file.pop('list'))
    end
  end

  context "#initiate_file" do
    should "create a file and make an entry in the file_list file" do
      FileUtils.mkdir_p('files')
      File.open('test_file', 'w') {|f| f.write('test')}
      @file_list_file.initiate_file('test_file', {'key' => 'value'})
      assert File.exists? 'files/test_file'
      FileUtils.rm_rf('files')
      FileUtils.rm('test_file')
    end
  end

  context "#is_uploaded?" do
    should "return the id if the file is uploaded" do
      assert_equal 1, @file_list_file.is_uploaded?('file1')
    end
    should "return false if file is not uploaded" do
      assert_equal nil, @file_list_file.is_uploaded?('file2')
    end
  end
end

class TestDirectoryManager < Test::Unit::TestCase
  include SSC::DirectoryManager

  def setup
    File.open(File.join(Dir.pwd, 'test_local_storage_file'), 'w') do |f|
      @data = {"list"   => [{"sub" => {1 => "one", 2 => "two"}}, 2, 3, 4],
               "add"    => [{"sub" => {1 => "one", 2 => "two"}}, 2, 3, 4],
               "remove" => [{"sub" => {1 => "one", 2 => "two"}}, 2, 3, 4]}
      f.write(@data.to_yaml)
    end
  end

  context "when file is available" do
    setup do
      @file= LocalStorageFile.new('test_local_storage_file')
      @location= File.join(Dir.pwd, 'test_local_storage_file')
    end

    should "initialize with the correct location" do
      assert_equal @location, @file.instance_variable_get('@location')
    end

    context "and when the path is provided" do
      should "initialize with the correct location" do
        @file= LocalStorageFile.new('test_local_storage_file', Dir.pwd)
        assert_equal @location, @file.instance_variable_get('@location')
      end
    end

    context "#valid?" do
      should "be true" do
        assert @file.valid?
      end
    end
    
    context "#pop" do
      should "return the latest entry in a given section" do
        assert_equal 4, @file.pop('add')
        assert !@file.instance_variable_get('@parsed_file')["add"].include?(4)
      end
      should "return nil if the section is empty" do
        assert_equal nil, @file.pop("empty_section")
      end
    end

    context "#push" do
      context "when section is already populated" do
        should "push the item onto the give section's list" do
          @file.push("add", 4)
          assert @file.instance_variable_get('@parsed_file')["add"].include?(4)
        end
      end

      context "when the section has not been initialized" do 
        should "create and add item to the section" do
          @file.push("empty_section", 1)
          assert @file.instance_variable_get('@parsed_file')["empty_section"] == [1]
        end
      end
    end

    context "#[]" do
      context "when the section exists" do
        should "return the list from the section" do
          assert @file["add"] == [{"sub" => {1 => "one", 2 => "two"}}, 2, 3, 4]
        end
      end
      context "when the section does not exist" do
        should "return a empty list" do
          assert @file["empty_section"] == []
        end
      end
    end

    context "#read" do
      should "return the parsed contents of the file if the file is available" do
        assert @file.read.is_a?(Hash)
        assert @file.read == @data
      end

      should "raise a file not found error if the file is unavilable" do
        assert_raise(Errno::ENOENT) do
          @file.instance_variable_set('@location', '/unknown/path/')
          @file.read
        end
      end
    end

    context  "#save" do
      should "write the modifiied data to the file" do
        @file.push('empty_section', 'random_data')
        @file.save
        assert @file.read.keys.include?('empty_section')
      end
    end

    context "#empty_list?" do
      should "return false if the 'list' section is non-empty" do
        assert !@file.empty_list?
      end

      should "return true if the 'list' section is empty" do
        [[], {}, nil].each do |item|
          @file.instance_variable_set('@parsed_file', {"list" => item})
          assert @file.empty_list?
        end
      end
    end
  end

  def teardown
    FileUtils.rm('./test_local_storage_file')
  end
end
