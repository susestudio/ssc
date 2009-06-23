class Request
  attr_accessor :request, :uri, :method, :call, :data

  def initialize method, call
    self.uri = URI.parse("#{base_url}/#{call}")
    if method == "GET"
      self.request = Net::HTTP::Get.new(self.uri.request_uri)
    elsif method == "POST"
      self.request = Net::HTTP::Post.new(self.uri.request_uri)
    elsif method == "PUT"
      self.request = Net::HTTP::Put.new(self.uri.request_uri)
    elsif method == "DELETE"
      self.request = Net::HTTP::Delete.new(self.uri.request_uri)
    end
    self.request.basic_auth($username, $password)
  end

  def go
    request.set_form_data(data, ";") unless data.nil?
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

  def set_multipart_data(params)
    boundary = Time.now.to_i.to_s(16)
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    body = ""
    params.each do |key,value|
      esc_key = CGI.escape(key.to_s)
      body << "--#{boundary}\r\n"
      if value.respond_to?(:read)
        body << "Content-Disposition: form-data; name=\"#{esc_key}\"; filename=\"#{File.basename(value.path)}\"\r\n"
        body << "Content-Type: #{mime_type(value.path)}\r\n\r\n"
        body << value.read
      else
        body << "Content-Disposition: form-data; name=\"#{esc_key}\"\r\n\r\n#{value}"
      end
      body << "\r\n"
    end
    body << "--#{boundary}--\r\n\r\n"
    request.body = body
    request["Content-Length"] = request.body.size
  end

  def mime_type(file)
    case
      when file =~ /\.jpg/ then 'image/jpg'
      when file =~ /\.gif$/ then 'image/gif'
      when file =~ /\.png$/ then 'image/png'
      else 'application/octet-stream'
    end
  end
end