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
  end
end
