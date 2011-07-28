$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))
require 'helper'

class TestAppliance < Test::Unit::TestCase
  context "appliance" do
    setup do
      @source_id= TEST_CONFIG[:appliance_ids]["default_jeos"]
      @auth_params= TEST_CONFIG.slice(:username, :password)
      @client= SSC::Base.new
      connection= StudioApi::Connection.new(@auth_params[:username], @auth_params[:password], "https://susestudio.com/api/v1/user/")
      StudioApi::Util.configure_studio_connection connection
    end

    context "create" do
      setup do
        params=  @auth_params.merge(:source_id => @source_id)
        @client.invoke "s_s_c:handler:appliance:create", ["test_appliance"], params
      end

      should "create an appliance directory. \
      create a .sscrc file. \
      populate .sscrc file. \
      create the appliance on studio" do
        assert Dir.exist?("./test_appliance")
        assert File.exist?("./test_appliance/.sscrc")
        parsed_file= YAML::load(File.read("./test_appliance/.sscrc"))
        assert parsed_file.is_a?(Hash)
        assert parsed_file["appliance_id"] if parsed_file
        appliance_id= parsed_file["appliance_id"].to_i
        APPLIANCES_CREATED << appliance_id
        assert_nothing_raised do
          StudioApi::Appliance.find(appliance_id)
        end
      end
    end

    context "list" do
      setup do
        @appliances= StudioApi::Appliance.find(:all).collect{|i| [ i.id, i.name ]}
      end
      should "return array of all available appliances" do
        response= @client.invoke "s_s_c:handler:appliance:list", [], @auth_params
        puts "response"
        puts response.inspect
        puts "Id: "+ @appliances.inspect
        assert (@appliances - response) == []
      end
    end

    context "info" do
      setup do
        @appliance= StudioApi::Appliance.find(:first)
      end

      should "return information about the appliance" do
        response= @client.invoke "s_s_c:handler:appliance:info", [], @auth_params.merge(:appliance_id => @appliance.id)
        assert response[0].match(/#{@appliance.id}.*#{@appliance.name}/)
        assert response.length == 3
      end
    end

    context "destroy" do
      setup do
        @appliance= StudioApi::Appliance.clone(@source_id)
        @client.invoke('s_s_c:handler:appliance:destroy', [], @auth_params.merge(:appliance_id => @appliance.id))
      end
      should "destroy remote appliance" do
        assert_raise(ActiveResource::BadRequest) do 
          StudioApi::Appliance.find(@appliance.id)
        end
      end
    end

    context "status" do
      setup do
        @appliance= StudioApi::Appliance.clone(@source_id)
        APPLIANCES_CREATED << @appliance.id
      end

      should "return the status of the appliance" do
        response= @client.invoke( 's_s_c:handler:appliance:status', [], @auth_params.merge(:appliance_id => @appliance.id) )
        assert response.match(/Ok/)
      end
    end

    def teardown
      APPLIANCES_CREATED.each do |id|
        appliance= begin
                     StudioApi::Appliance.find(id)
                   rescue
                     nil
                   end
        if appliance
          appliance.destroy
        end
      end
      FileUtils.rmdir("./test_appliance")
    end
  end
end
