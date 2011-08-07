require 'helper'

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
