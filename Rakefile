require 'rubygems'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s| 
  s.name = "ssc"
  s.version = "0.1"
  s.author = "Andre Duffeck"
  s.email = "aduffeck@suse.de"
  s.homepage = "http://git.opensuse.org/?p=projects/ssc.git;a=summary"
  s.platform = Gem::Platform::RUBY
  s.summary = "A commandline client for SUSE Studio"
  s.files = FileList["{bin,lib}/**/*"].to_a
  s.executables << "ssc"
  s.require_path = "lib"
  s.extra_rdoc_files = ["README"]
  s.add_dependency("ruby-xml-smart", ">= 0.2")
  s.add_dependency("net-netrc", ">= 0.2.1")
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

task :default => "pkg/#{spec.name}-#{spec.version}.gem" do
    puts "generated latest version"
end

