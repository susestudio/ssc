#!/usr/bin/env ruby

require 'request.rb'


class CommandHandler
   def self.doRequest r
    xml, success = r.go
    if success
     return xml
    else
      handle_error xml
    end
   end

  def self.handle_error s
    xml = XML::Smart.string(s)
    if xml.find("/error/code").length > 0
      STDERR.puts "Error '#{xml.find("/error/code").first.to_s}' occured.\nMessage: #{xml.find("/error/message").first.to_s}"
    else
      STDERR.puts "Server returned: #{s}"
    end
    exit 1
  end

  def self.download_file url, target
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth($username, $password)
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = 45
      response = http.request(request)
      open(target, "wb") do |file|
        file.write(response.body)
      end
    end
  end
end