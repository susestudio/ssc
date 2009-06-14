#!/usr/bin/env ruby

require 'commandhandler'

class CheckoutHandler < CommandHandler
  def self.checkout args, images
    appliance = get_appliance_from_args_or_config args
    # Get appliance
    r = Request.new
    r.method = "GET"
    r.call = "appliances/#{appliance}"
    s = doRequest(r)
    appliancexml  =XML::Smart.string( s )
    id = appliancexml.find("appliance/id").first.to_s
    base_system = appliancexml.find("appliance/basesystem").first.to_s
    puts "Checkout '#{appliancexml.find("appliance/name").first.to_s}'\n"

    FileUtils.mkdir_p id
    [ ".ssc", ".ssc/files", ".ssc/rpms", "files", "rpms", "images"].each do |d|
      FileUtils.mkdir_p id + "/" + d
    end

    XML::Smart.modify("#{id}/.ssc/appliance.config","<checkout/>") { |doc|
      node = doc.root.add("appliance_id", id)
      node = doc.root.add("appliance_name", appliancexml.find("appliance/name").first.to_s)
      node = doc.root.add("base_system", appliancexml.find("appliance/basesystem").first.to_s)
    }

    # Get files
    r = Request.new
    r.method = "GET"
    r.call = "files/?appliance_id=#{appliance}"
    s = doRequest(r)

    filesxml = XML::Smart.string( s )
    filesxml.find("files/file").each do |f|
      filename = f.find("filename").first.to_s
      fileid = f.find("id").first.to_s
      path = "#{id}/files/#{filename}"
      puts "  Downloading '#{filename}'"

      download_file "#{base_url}/files/#{fileid}/data", path
      FileUtils.cp path, "#{id}/.ssc/files/#{filename}.orig"
      download_file "#{base_url}/files/#{fileid}", "#{id}/.ssc/files/#{filename}.config"
      XML::Smart.modify("#{id}/.ssc/files/#{filename}.config") do |doc|
        node = doc.find("/file").first
        node.add("state", "synched")
      end
    end

    # Get rpms
    r = Request.new
    r.method = "GET"
    r.call = "rpms?base_system=#{base_system}"
    s = doRequest(r)

    rpmsxml = XML::Smart.string( s )
    rpmsxml.find("rpms/rpm").each do |rpm|
      filename = rpm.find("filename").first.to_s
      fileid = rpm.find("id").first.to_s
      path = "#{id}/rpms/#{filename}"
      puts "  Downloading '#{filename}'"

      download_file "#{base_url}/rpms/#{fileid}/data", path
      FileUtils.cp path, "#{id}/.ssc/rpms/#{filename}.orig"
      download_file "#{base_url}/rpms/#{fileid}", "#{id}/.ssc/rpms/#{filename}.config"
      XML::Smart.modify("#{id}/.ssc/rpms/#{filename}.config") do |doc|
        node = doc.find("/rpm").first
        node.add("state", "synched")
      end
    end

    if images
      appliancexml.find("appliance/builds/build").each do |build|
        url = build.find("download_url").first.to_s
        puts "  Downloading image '#{File.basename(url)}'"
        download_file url, "#{id}/images/#{File.basename(url)}"
      end
    else
      puts "  Skipped downloading images (change with -i)'"
    end
  end

  def self.status
    appliance_config = XML::Smart.open(".ssc/appliance.config")
    id = appliance_config.find("/checkout/appliance_id").first.to_s
    name = appliance_config.find("/checkout/appliance_name").first.to_s

    show_files = false
    unknown_files = Array.new
    added_files = Array.new
    modified_files = Array.new
    removed_files = Array.new
    Dir.entries("files").each do |file|
      if [".", ".."].include?(file) then next end
      if File.exists?(".ssc/files/#{file}.config")
        xml = XML::Smart.open(".ssc/files/#{file}.config")
        status = xml.find("file/state").first.to_s
        if status == "added"
          added_files << file
          show_files = true
        elsif status == "synched"
          oldmd5 = `md5sum .ssc/files/#{file}.orig`.split[0]
          md5 = `md5sum files/#{file}`.split[0]
          if md5 == oldmd5
            next
          elsif md5 != oldmd5
            modified_files << file
            show_files = true
          end
        end
      else
          unknown_files << file
          show_files = true
      end
    end
    Dir.entries(".ssc/files").each do |file|
      if [".", ".."].include?(file) then next end
      unless file =~ /.*.config$/ then next end
      xml = XML::Smart.open(".ssc/files/#{file}")
      if xml.find("file/state").first.to_s == "removed"
        removed_files << file.sub(/(.*).config$/, "\\1")
        show_files = true
      end
    end

    show_rpms = false
    unknown_rpms = Array.new
    added_rpms = Array.new
    modified_rpms = Array.new
    removed_rpms = Array.new
    Dir.entries("rpms").each do |file|
      if [".", ".."].include?(file) then next end
      if File.exists?(".ssc/rpms/#{file}.config")
        xml = XML::Smart.open(".ssc/rpms/#{file}.config")
        status = xml.find("rpm/state").first.to_s
        if status == "added"
          added_rpms << file
          show_rpms = true
        elsif status == "synched"
          oldmd5 = `md5sum .ssc/rpms/#{file}.orig`.split[0]
          md5 = `md5sum rpms/#{file}`.split[0]
          if md5 == oldmd5
            next
          elsif md5 != oldmd5
            modified_rpms << file
            show_rpms = true
          end
        end
      else
          unknown_rpms << file
          show_rpms = true
      end
    end
    Dir.entries(".ssc/rpms").each do |file|
      if [".", ".."].include?(file) then next end
      unless file =~ /.*.config$/ then next end
      xml = XML::Smart.open(".ssc/rpms/#{file}")
      if xml.find("rpm/state").first.to_s == "removed"
        removed_rpms << file.sub(/(.*).config$/, "\\1")
        show_rpms = true
      end
    end

    puts "Status of #{name} (#{id}):"
    if show_files
      puts " Overlay files:"
      unknown_files.each {|f| puts "   ? #{f}"}
      modified_files.each {|f| puts "   M #{f}"}
      added_files.each {|f| puts "   A #{f}"}
      removed_files.each {|f| puts "   D #{f}"}
    end
    if show_rpms
      puts " RPMs:"
      unknown_rpms.each {|f| puts "   ? #{f}"}
      modified_rpms.each {|f| puts "   M #{f}"}
      added_rpms.each {|f| puts "   A #{f}"}
      removed_rpms.each {|f| puts "   D #{f}"}
    end
    unless show_files or show_rpms
      puts "Nothing changed."
    end
  end

  def self.commit
    appliance = get_appliance_from_args_or_config nil
    appliance_config = XML::Smart.open(".ssc/appliance.config")
    base = appliance_config.find("checkout/base_system").first.to_s

    Dir.entries(".ssc/rpms").each do |file|
      next unless file =~ /.config$/
      config = XML::Smart.open(".ssc/rpms/" + file)
      filename = file.gsub(/(.*).config$/, "\\1")
      status = config.find("rpm/state").first.to_s

      if (status == "added")
        puts "Uploading #{filename}"
        s = `curl -u #{$username}:#{$password} -XPOST -F\"file=@#{"rpms/" + filename}\" http://#{$username}:#{$password}@#{$server_name}/#{$api_prefix}/rpms?base_system=#{base} 2> /dev/null`
        xml = XML::Smart.string(s)
        id = xml.find("rpm/id").first.to_s unless xml.find("rpm/id").length == 0
        if id
          FileUtils.cp "rpms/#{filename}", ".ssc/rpms/#{filename}.orig"
          download_file "#{base_url}/rpms/#{id}", ".ssc/rpms/#{filename}.config"
        end
      elsif (status == "removed")
        puts "Removing #{filename}"
        id = config.find("rpm/id").first.to_s
        r = Request.new
        r.method = "DELETE"
        r.call = "rpms/#{id}"
        doRequest(r)
        FileUtils.rm ".ssc/rpms/#{filename}.orig"
        FileUtils.rm ".ssc/rpms/#{filename}.config"
      else
        oldmd5 = `md5sum .ssc/rpms/#{filename}.orig`.split[0]
        md5 = `md5sum rpms/#{filename}`.split[0]
        if (status == "synched" and md5 != oldmd5)
          id = config.find("rpm/id").first.to_s
          puts "Updating #{filename}"
          `curl -u #{$username}:#{$password} -XPUT -F\"file=@#{"rpms/" + filename}\" http://#{$username}:#{$password}@#{$server_name}/#{$api_prefix}/rpms/#{id}/data 2> /dev/null`
          download_file "#{base_url}/rpms/#{id}", ".ssc/rpms/#{filename}.config"
        end
      end
    end
    Dir.entries(".ssc/files").each do |file|
      next unless file =~ /.config$/
      config = XML::Smart.open(".ssc/files/" + file)
      filename = file.gsub(/(.*).config$/, "\\1")
      status = config.find("file/state").first.to_s

      if (status == "added")
        puts "Uploading #{filename}"
        s = `curl -u #{$username}:#{$password} -XPOST -F\"file=@#{"files/" + filename}\" http://#{$username}:#{$password}@#{$server_name}/#{$api_prefix}/files?appliance_id=#{appliance} 2> /dev/null`
        xml = XML::Smart.string(s)
        id = xml.find("file/id").first.to_s unless xml.find("file/id").length == 0
        if id
          FileUtils.cp "files/#{filename}", ".ssc/files/#{filename}.orig"
          download_file "#{base_url}/files/#{id}", ".ssc/files/#{filename}.config"
        end
      elsif (status == "removed")
        puts "Removing #{filename}"
        id = config.find("file/id").first.to_s
        r = Request.new
        r.method = "DELETE"
        r.call = "files/#{id}"
        doRequest(r)
        FileUtils.rm ".ssc/files/#{filename}.orig"
        FileUtils.rm ".ssc/files/#{filename}.config"
      else
        oldmd5 = `md5sum .ssc/files/#{filename}.orig`.split[0]
        md5 = `md5sum files/#{filename}`.split[0]
        if ((status == "synched" or status == "modified") and md5 != oldmd5)
          id = config.find("file/id").first.to_s
          puts "Updating #{filename}"
          `curl -u #{$username}:#{$password} -XPUT -F\"file=@#{"files/" + filename}\" http://#{$username}:#{$password}@#{$server_name}/#{$api_prefix}/files/#{id}/data 2> /dev/null`
          download_file "#{base_url}/files/#{id}", ".ssc/files/#{filename}.config"
        end
      end
    end
  end

  def self.add args
    filename = args[1]
    unless File.exists?(filename)
      STDERR.puts "File '#{filename}' does not exist."
      return 1
    end
    f = File.open(filename)
    path = File.expand_path(filename)
    basename = File.basename(path)
    if path =~ /.*\/rpms\/#{basename}/
      XML::Smart.modify(".ssc/rpms/#{basename}.config","<rpm/>") { |doc|
        node = doc.root.add("state", "added")
      }
    elsif path =~ /.*\/files\/#{basename}/
      XML::Smart.modify(".ssc/files/#{basename}.config","<file/>") { |doc|
        node = doc.root.add("state", "added")
      }
    else
      STDERR.puts "Only files in /rpms and /files can be added."
      return 1
    end
  end

  def self.remove args
    filename = args[1]
    path = File.expand_path(filename)
    basename = File.basename(path)
    if path =~ /.*\/rpms\/#{basename}/
      type = "rpm"
    elsif path =~ /.*\/files\/#{basename}/
      type = "file"
    else
      STDERR.puts "Only files in /rpms and /files can be removed."
      return 1
    end
    unless File.exists?(".ssc/#{type}s/#{basename}.config")
      STDERR.puts "The file does not belong to the checkout and can not be removed."
      return 1
    end

    XML::Smart.modify(".ssc/#{type}s/#{basename}.config") { |doc|
      nodes = doc.find("#{type}/state")
      nodes.delete_at!(0)
      doc.root.add("state", "removed")
    }
    FileUtils.rm filename
  end

end