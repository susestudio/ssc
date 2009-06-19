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

  def self.modify_file args
    
  end
end