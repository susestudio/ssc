require 'helper'

class TestArgumentParser < Test::Unit::TestCase
  context "SSC::ArgumentParser" do
  
    context "when arguments are good" do
      setup do
        @parser= SSC::ArgumentParser.new(['appliance', 'create', 'act_arg1', 'act_arg2', '--option', 'value', '-o', 'v', '--flag', '-f'])
      end

      should "set @klass to Appliance" do
        assert_equal SSC::Handler::Appliance, @parser.klass
      end

      should "set @action to create" do
        assert_equal 'create', @parser.action
      end

      should "set @options to option hash" do
        assert_equal({:option => 'value',
                      :o      => 'v',
                      :flag   => true,
                      :f      => true }, @parser.options)
      end

      should "set @action_arguments to argument array" do
        #only one of the arguments must be taken since create take only one argument
	assert_equal(['act_arg1'], @parser.action_arguments)
      end

      should "have the entire list if arity of the method is -1(splat)" do
        parser= SSC::ArgumentParser.new(['repository', 'add', 'act_arg1', 'act_arg2'])
        assert_equal(['act_arg1', 'act_arg2'], parser.action_arguments )
      end

    end
  end

  context "when handler is unknown" do
    should "raise UnkownOptionError" do
      assert_raise(SSC::UnkownOptionError) do
        SSC::ArgumentParser.new(['apliance', 'create'])
      end
    end
  end

  context "when handler method is unknown" do
    should "raise UnkownOptionError" do
      assert_raise(SSC::UnkownOptionError) do
        SSC::ArgumentParser.new(['appliance', 'unkown_method'])
      end
    end
  end

end
