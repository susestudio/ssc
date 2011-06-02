require 'helper'

class TestSsc < Test::Unit::TestCase
  context "SSC::Base" do
    setup do
      File.open('.sscrc', 'w') {|f| f.write("username: user\npassword: pass")}
      @client= SSC::Base.new(['appliance', 'create', '--option', 'value', 
                             '-o', 'v', '--flag', '-f'])
      @specific_client= SSC::Base.new(['appliance', 'create', 
				       '--username', 'user1', 
				       '--password', 'pass1'])
      FileUtils.rm('.sscrc')
    end

    context "when username and password are passed in the command line" do
      should "override username and password in ./.sscrc" do
	assert_equal({:username => 'user1', :password => 'pass1'}, 
		     @specific_client.instance_variable_get('@options'))
      end
    end

    should "initialize handler class correctly" do
      assert_equal SSC::Handler::Appliance, 
        @client.instance_variable_get('@klass')
    end

    should "initialize @args with an ArgumentParser object" do
      args= @client.instance_variable_get('@args')
      assert_equal SSC::ArgumentParser, args.class
    end

    should "initialize @config with the config from .sscrc" do
      options= @client.instance_variable_get('@options')
      assert_equal('user', options[:username])
      assert_equal('pass', options[:password])
    end

  end
end
