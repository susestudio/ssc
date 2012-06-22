# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ssc}
  s.version = "0.4.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ratan Sebastian"]
  s.date = %q{2011-09-07}
  s.default_executable = %q{ssc}
  s.description = %q{Command-line client for Suse Studio}
  s.email = %q{rjsvaljean@gmail.com}
  s.executables = ["ssc"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "Gemfile",
    "Gemfile.lock",
    "MIT-LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "bin/ssc",
    "lib/directory_manager.rb",
    "lib/handlers/all.rb",
    "lib/handlers/appliance.rb",
    "lib/handlers/build.rb",
    "lib/handlers/file.rb",
    "lib/handlers/helper.rb",
    "lib/handlers/package.rb",
    "lib/handlers/repository.rb",
    "lib/handlers/template.rb",
    "lib/ssc.rb",
    "ssc.gemspec",
    "test/helper.rb",
    "test/integration/test_appliance.rb",
    "test/integration/test_file.rb",
    "test/integration/test_package.rb",
    "test/integration/test_repository.rb",
    "test/unit/test_directory_manager.rb"
  ]
  s.homepage = %q{http://github.com/rjsvaljean/ssc}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Command-line client for Suse Studio}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<studio_api>, [">= 3.1.2"])
      s.add_runtime_dependency(%q<thor>, [">= 0.14.6"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.0"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
    else
      s.add_dependency(%q<studio_api>, [">= 3.1.2"])
      s.add_dependency(%q<thor>, [">= 0.14.6"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.0"])
      s.add_dependency(%q<simplecov>, [">= 0"])
    end
  else
    s.add_dependency(%q<studio_api>, [">= 3.1.2"])
    s.add_dependency(%q<thor>, [">= 0.14.6"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.0"])
    s.add_dependency(%q<simplecov>, [">= 0"])
  end
end

