class Request
  attr_accessor :method, :call, :data

  def go
    uri = URI.parse("#{base_url}/#{call}")
    request = nil
    if method == "GET"
      request = Net::HTTP::Get.new(uri.request_uri)
    elsif method == "POST"
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(data, ";") unless data.nil?
    elsif method == "DELETE"
      request = Net::HTTP::Delete.new(uri.request_uri)
    end
    request.basic_auth($username, $password)
    begin
      Net::HTTP.start(uri.host, uri.port) do |http|
        http.read_timeout = 45
        response = http.request(request)
        unless( response.kind_of? Net::HTTPSuccess )
          return [response.body, false]
        end
        return [response.body, true]
      end
    rescue => e
      return ["Error: #{e.to_s}", false]
    end
  end
end