#!/usr/bin/env ruby

require 'commandhandler'

class ApplianceHandler < CommandHandler
  def self.list_appliances
    r = Request.new
    r.method = "GET"
    r.call = "appliances"
    s = doRequest(r)

    xml = XML::Smart.string( s )
    res = String.new
    xml.find("/appliances/appliance").each do |a|
      res << "#{a.find("id").first.to_s}: #{a.find("name").first.to_s} (based on #{a.find("basesystem").first.to_s})\n"
      res << "  Cloned from: #{a.find("parent/name").first.to_s} (#{a.find("parent/id").first.to_s})\n" unless a.find("parent/name").length == 0
      res << "  Builds:      #{a.find("builds/build").length} (#{a.find("builds/build/compressed_image_size").inject(0){|sum,item| sum + item.to_i}})\n"
      res << "\n"
    end
    puts res
  end

  def self.clone_appliance args
    clonefrom = args[1]
    if clonefrom.nil? || clonefrom.empty?
      STDERR.puts "You need to specify a template."
      exit 1
    end
    r = Request.new
    r.method = "POST"
    r.call = "appliances?clone_from=#{clonefrom}"
    s = doRequest(r)

    xml = XML::Smart.string( s )
    res = String.new
    res << "Created Appliance: #{xml.find("/appliance/name").first.to_s}\n"
    res << "  Id:          " + xml.find("/appliance/id").first.to_s + "\n"
    res << "  Based on:    " + xml.find("/appliance/basesystem").first.to_s + "\n"
    res << "  Cloned from: #{xml.find("/appliance/parent/name").first.to_s} (#{xml.find("/appliance/parent/id").first.to_s})\n" unless xml.find("/appliance/parent/name").length == 0
    puts res
  end

  def self.delete_appliance args
    appliance = get_appliance_from_args_or_config args
    r = Request.new
    r.method = "DELETE"
    r.call = "appliances/#{appliance}"
    doRequest(r)
    puts "Success."
  end

  def self.template_sets
    r = Request.new
    r.method = "GET"
    r.call = "template_sets"
    s = doRequest(r)

    xml = XML::Smart.string( s )
    res = String.new
    xml.find("/template_sets/template_set").each do |ts|
      res << "'#{ts.find("name").first.to_s}' Templates (#{ts.find("description").first.to_s}):\n"
      ts.find("template").each do |t|
        res << " #{t.find("appliance_id").first.to_s}: #{t.find("name").first.to_s} (based on #{t.find("basesystem").first.to_s})\n"
        res << "    Description: #{t.find("description").first.to_s}\n\n"
      end
    end
    puts res
  end
end
