require 'helper'

class TestSsc < Test::Unit::TestCase
  context "SSC::Base" do
    setup do
      File.open('.sscrc', 'w') {|f| f.write("username: user\npassword: pass")}
      @client= SSC::Base.new(['appliance', 'create', '--option', 'value', 
                             '-o', 'v', '--flag', '-f'])
      FileUtils.rm('.sscrc')
    end

    should "initialize handler class correctly" do
      assert_equal @client.instance_variable_get('@klass').class, 
        SSC::Handler::Appliance
    end

    should "initialize @args with an ArgumentParser object" do
      args= @client.instance_variable_get('@args')
      assert_equal args.class, SSC::ArgumentParser
    end

    should "initialize @config with the config from .sscrc" do
      config= @client.instance_variable_get('@config')
      assert_equal config, {'username' => 'user', 'password' => 'pass'}
    end

  end
end
