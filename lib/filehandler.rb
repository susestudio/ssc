#!/usr/bin/env ruby

require 'commandhandler'

class FileHandler < CommandHandler
  def self.show_file args
    filename = args[1]
    unless filename
      STDERR.puts "You need to specify a file."
      return 1
    end
    path = File.expand_path(filename)
    basename = File.basename(path)
    if path =~ /.*\/files\/#{basename}/
      type = "file"
    else
      STDERR.puts "This command can only be invoked on overlay files in /files."
      return 1
    end
    unless File.exists?(".ssc/#{type}s/#{basename}.config")
      STDERR.puts "The file does not belong to the checkout and can not be removed."
      return 1
    end
    XML::Smart.modify(".ssc/#{type}s/#{basename}.config") { |doc|
      nodes = doc.find("#{type}/state")
      if( nodes.first.to_s == "added" )
        puts "The file has just been added. Further information is only available after a commit."
        return 0
      else
        puts "Id:\t\t#{doc.find("file/id").first.to_s}"
        puts "Filename:\t#{doc.find("file/filename").first.to_s}"
        puts "Path:\t\t#{doc.find("file/path").first.to_s}"
        puts "Owner:\t\t#{doc.find("file/owner").first.to_s}"
        puts "Group:\t\t#{doc.find("file/group").first.to_s}"
        puts "Permissions:\t#{doc.find("file/permissions").first.to_s}"
        puts "Enabled:\t#{doc.find("file/enabled").first.to_s}"
        puts "Size:\t\t#{doc.find("file/size").first.to_s}"
      end
    }
  end

  def self.modify_file args, config
    filename = args[1]
    unless filename
      STDERR.puts "You need to specify a file."
      return 1
    end
    path = File.expand_path(filename)
    basename = File.basename(path)
    if path =~ /.*\/files\/#{basename}/
      type = "file"
    else
      STDERR.puts "This command can only be invoked on overlay files in /files."
      return 1
    end
    unless File.exists?(".ssc/#{type}s/#{basename}.config")
      STDERR.puts "The file does not belong to the checkout and can not be removed."
      return 1
    end
    modified = false
    XML::Smart.modify(".ssc/#{type}s/#{basename}.config") { |doc|
      ["filename", "path", "owner", "group", "permissions", "enabled"].each do |a|
        if config[a]
          doc.find("file/#{a}").delete_at!(0) if doc.find("file/#{a}").length > 0
          doc.find("file").first.add(a, config[a])
          modified = true
        end
      end

      if modified
        if doc.find("file/state").length > 0 and doc.find("file").first.to_s != "added"
          doc.find("file/state").delete_at!(0)
          doc.find("file").first.add("state", "modified")
        end
      else
        STDERR.puts "You need to specify an attribute to modify."
        exit 1
      end


      puts "Id:\t\t#{doc.find("file/id").first.to_s}"
      puts "Filename:\t#{doc.find("file/filename").first.to_s}"
      puts "Path:\t\t#{doc.find("file/path").first.to_s}"
      puts "Owner:\t\t#{doc.find("file/owner").first.to_s}"
      puts "Group:\t\t#{doc.find("file/group").first.to_s}"
      puts "Permissions:\t#{doc.find("file/permissions").first.to_s}"
      puts "Enabled:\t#{doc.find("file/enabled").first.to_s}"
      puts "Size:\t\t#{doc.find("file/size").first.to_s}"
    }
  end
end