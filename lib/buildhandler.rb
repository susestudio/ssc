#!/usr/bin/env ruby

require 'commandhandler'

class BuildHandler < CommandHandler

  def self.handle_error s
    xml = XML::Smart.string(s)
    if xml.find("/error/code").length > 0 && xml.find("/error/code").first.to_s == "image_already_exists"
      STDERR.puts "This image has alread been build (force overwrite with -f)."
      exit 1
    else
      super s
    end
  end

  def self.build_appliance args, config
    appliance = get_appliance_from_args_or_config args
    call = "running_builds?appliance_id=#{appliance}"
    call += "&force=1" if config[:force]
    r = Request.new "POST", call
    s = doRequest(r)

    xml = XML::Smart.string( s )
    res = String.new
    res << "Triggered build: #{xml.find("/build/id").first.to_s}" unless xml.find("/build/id").length == 0
    puts res
  end

  def self.list_running_builds args
    appliance = get_appliance_from_args_or_config args
    r = Request.new "GET", "running_builds/?appliance_id=#{appliance}"
    s = doRequest(r)

    xml = XML::Smart.string( s )
    res = String.new
    xml.find("/running_builds/running_build").each do |rb|
      res << "#{rb.find("id").first.to_s}: #{rb.find("state").first.to_s}"
      res << ", #{rb.find("percent").first.to_s}% done - #{rb.find("message").first.to_s} (#{rb.find("time_elapsed").first.to_s}s elapsed)" unless xml.find("state").first.to_s == "error"
    end
    puts res unless res.empty?
  end

  def self.show_running_build args, config
    build = args[1]
    if build.nil? || build.empty?
      STDERR.puts "You need to specify a running build."
      exit 1
    end
    r = Request.new "GET", "running_builds/#{build}"
    while 1
      s = doRequest(r)

      xml = XML::Smart.string( s )
      res = String.new
      return unless xml.find("/running_build/id").length > 0
      res << xml.find("/running_build/state").first.to_s
      res << ", #{xml.find("/running_build/percent").first.to_s}% done - #{xml.find("/running_build/message").first.to_s} (#{xml.find("/running_build/time_elapsed").first.to_s}s elapsed)" unless xml.find("/running_build/state").first.to_s == "error"
      puts res
      exit 0 if !config[:follow] or xml.find("/running_build/state").first.to_s != "running"
      sleep 5
    end
  end

  def self.list_builds args
    appliance = get_appliance_from_args_or_config args
    r = Request.new "GET", "builds/?appliance_id=#{appliance}"
    s = doRequest(r)

    xml = XML::Smart.string( s )
    res = String.new
    xml.find("/builds/build").each do |rb|
      res << "#{rb.find("id").first.to_s}: #{rb.find("state").first.to_s}"
      res << ", v#{rb.find("version").first.to_s} (#{rb.find("image_type").first.to_s})"
      res <<  " (#{rb.find("compressed_image_size").first.to_s} MB)" if rb.find("compressed_image_size").length > 0
      res << " #{rb.find("download_url").first.to_s}" if rb.find("download_url").length > 0
      res << "\n"
    end
    puts res unless res.empty?
  end

  def self.show_build args
    build = args[1]
    if build.nil? || build.empty?
      STDERR.puts "You need to specify a build."
      exit 1
    end
    r = Request.new "GET", "builds/#{build}"
    s = doRequest(r)

    xml = XML::Smart.string( s )
    res = String.new
    xml.find("/build").each do |rb|
      res << "#{rb.find("id").first.to_s}: #{rb.find("state").first.to_s}"
      res << ", v#{rb.find("version").first.to_s} (#{rb.find("image_type").first.to_s})"
      res <<  " (#{rb.find("size").first.to_s}/#{rb.find("compressed_image_size").first.to_s} MB)" if rb.find("size").length > 0
      res << " #{rb.find("download_url").first.to_s}" if rb.find("download_url").length > 0
    end
    puts res unless res.empty?
  end

  def self.cancel_build args
    build = args[1]
    if build.nil? || build.empty?
      STDERR.puts "You need to specify a build."
      exit 1
    end
    r = Request.new "DELETE", "running_builds/#{build}"
    doRequest(r)
    puts "Success."
  end

  def self.delete_build args
    build = args[1]
    if build.nil? || build.empty?
      STDERR.puts "You need to specify a build."
      exit 1
    end
    r = Request.new "DELETE", "builds/#{build}"
    doRequest(r)
    puts "Success."
  end
end