require 'helper'

class TestHandlerHelper < Test::Unit::TestCase
  context "SSC::Handler::Helper" do
    setup do
      class TestObject
        include SSC::Handler::Helper
      end

      @objekt= TestObject.new
    end

    context "#authorize" do
      should "create connection and configure StudioApi to use it" do
        mock_connection= mock('connection')
        StudioApi::Connection.expects(:new).with('user', 'pass', 'https://susestudio.com/api/v1/user').returns(mock_connection)
        StudioApi::Util.expects(:configure_studio_connection).with(mock_connection)
        @objekt.authorize('user', 'pass')
      end
    end
  end
end
