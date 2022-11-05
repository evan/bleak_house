$:.push File.expand_path("../lib", __FILE__)

require "bleak_house/version"

Gem::Specification.new do |s|
  s.name = %q{bleak_house}
  s.version = "7.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Test"]
  s.date = %q{2009-11-18}
  s.default_executable = %q{bleak}
  s.description = %q{A library for finding memory leaks.}
  s.email = %q{}
  s.executables = ["bleak"]
  s.extensions = ["ext/extconf.rb"]
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "LICENSE_BSD", "TODO", "ext/snapshot.c", "lib/bleak_house.rb", "lib/bleak_house/analyzer.rb", "lib/bleak_house/hook.rb"]
  s.files = ["CHANGELOG", "LICENSE", "LICENSE_BSD", "Manifest", "Rakefile", "TODO", "bin/bleak", "ext/build_ruby.rb", "ext/build_snapshot.rb", "ext/extconf.rb", "ext/snapshot.c", "ext/snapshot.h", "lib/bleak_house.rb", "lib/bleak_house/analyzer.rb", "lib/bleak_house/hook.rb", "ruby/ruby-1.8.7-p174.tar.bz2", "ruby/ruby-1.8.7.patch", "test/benchmark/bench.rb", "test/test_helper.rb", "test/unit/test_bleak_house.rb", "bleak_house.gemspec"]
  s.homepage = %q{http://blog.evanweaver.com/files/doc/fauna/bleak_house/}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Bleak_house", "--main"]
  s.require_paths = ["lib", "ext"]
  s.rubyforge_project = %q{fauna}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A library for finding memory leaks.}
  s.test_files = ["test/test_helper.rb", "test/unit/test_bleak_house.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
