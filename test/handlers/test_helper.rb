require 'helper'

class TestHandlerHelper < Test::Unit::TestCase
  context "SSC::Handler::Helper" do
    setup do
      class TestObject
        include SSC::Handler::Helper
      end

      @objekt= TestObject.new
    end

    context "#connect" do
      should "create connection and configure StudioApi to use it" do
        mock_connection= mock('connection')
        StudioApi::Connection.expects(:new)
          .with('user', 'pass', 'https://susestudio.com/api/v1/user', 
                {:proxy => 'proxy'})
          .returns(mock_connection)
        StudioApi::Util.expects(:configure_studio_connection).with(mock_connection)
        @objekt.connect('user', 'pass', {:proxy => 'proxy', :another_option => 'value'})
      end
    end

    context "#filter_options" do
      should "return a hash of only the specified keys" do
        out= @objekt.filter_options({:a => 'a', :b => 'b'}, [:a])
        assert_equal({:a => 'a'}, out)
      end
    end

    context "#require_appliance_id" do
      should "raise and error if the appliance id option is not passed" do
        assert_raise(RuntimeError) { @objekt.require_appliance_id({}) }
      end

      should "not raise error if appliance id is provided" do
        StudioApi::Appliance.expects(:find).with(1).returns(nil)
        assert_nothing_raised do 
          @objekt.require_appliance_id(:appliance_id=>1) {|i| i}
        end
      end
    end
  end
end
