# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{carpool}
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brent Kirby"]
  s.date = %q{2010-09-12}
  s.description = %q{Carpool is a single sign on solution for Rack-based applications allowing you to persist sessions across domains.}
  s.email = %q{dev@kurbmedia.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "carpool.gemspec",
     "init.rb",
     "lib/carpool.rb",
     "lib/carpool/driver.rb",
     "lib/carpool/mixins.rb",
     "lib/carpool/passenger.rb",
     "lib/carpool/seatbelt.rb",
     "test/helper.rb",
     "test/test_carpool.rb"
  ]
  s.homepage = %q{http://github.com/kurbmedia/carpool}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Single Sign On solution for Rack-Based applications}
  s.test_files = [
    "test/helper.rb",
     "test/test_carpool.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
      s.add_runtime_dependency(%q<fast-aes>, [">= 0"])
    else
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
      s.add_dependency(%q<fast-aes>, [">= 0"])
    end
  else
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    s.add_dependency(%q<fast-aes>, [">= 0"])
  end
end

