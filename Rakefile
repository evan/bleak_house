require 'rubygems'
require 'rake'
require 'lib/bleak_house/rake_task_redefine_task'

begin
  require 'rake/clean'
  gem 'echoe', '>= 1.2'
  require 'echoe'
  require 'fileutils'
  include FileUtils

  CLEAN.include ['**/.*.sw?', '*.gem', '.config']  
  VERS = `cat CHANGELOG`[/^([\d\.]+)\. /, 1]
  
  taskmsg = File.open(File.dirname(__FILE__) + "/tasks/bleak_house_tasks.rake").readlines
  taskmsg = taskmsg[0..3] + [taskmsg[7][2..-1]] + taskmsg[9..-1]
  
  echoe = Echoe.new("bleak_house", VERS) do |p|
    p.author = "Evan Weaver" 
    p.rubyforge_name = "fauna"
    p.name = "bleak_house"
    p.description = "BleakHouse is a Rails plugin for finding memory leaks. It tracks ObjectSpace for your entire app, and produces charts of references by controller, by action, and by object class."
    p.changes = `cat CHANGELOG`[/^([\d\.]+\. .*)/, 1]
    p.email = "evan at cloudbur dot st"
    p.summary = p.description
    p.url = "http://blog.evanweaver.com"
    p.need_tar = false
    p.need_tar_gz = true
    p.test_globs = ["*_test.rb"]
    p.extra_deps = ["RubyInline"]
    p.clean_globs = CLEAN  
    p.spec_extras = {:post_install_message => 
"
Thanks for installing Bleak House #{VERS}. 

For each Rails app you want to profile, you will need to add the following 
rake task in RAILS_ROOT/lib/tasks/bleak_house_tasks.rake to be able to run 
the analyzer: 
" + taskmsg.join("  ") + "\n"}
  end
            
rescue LoadError => boom
  puts "You are missing a dependency required for meta-operations on this gem."
  puts "#{boom.to_s.capitalize}."
  
  desc 'Run the default tasks'
  task :default => :test
end

desc 'Do nothing.'
Rake::Task.redefine_task("test") do
   puts "There are no tests. You could totally write some, though."
#   system "ruby -Ibin:lib:test test/unit/polymorph_test.rb #{ENV['METHOD'] ? "--name=#{ENV['METHOD']}" : ""}"
end

desc 'Build the patched Ruby binary.'
namespace :ruby do
  task :build do    
    require 'open-uri'
    require 'fileutils'
    puts "building patched Ruby binary"
    tmp = "/tmp/"
    Dir.chdir(tmp) do
      build_dir = "bleak_house"
      FileUtils.rm_rf(build_dir) rescue nil
      Dir.mkdir(build_dir)
      begin
        Dir.chdir(build_dir) do
          puts "  downloading Ruby source"
          bz2 = "ruby-1.8.6.tar.bz2"
          system("wget 'http://rubyforge.org/frs/download.php/20425/ruby-1.8.6.tar.bz2' &> wget.log")
          puts "  extracting"
          system("tar xjf #{bz2} &> tar.log")
          File.delete bz2
          Dir.chdir("ruby-1.8.6") do
            puts "  patching" or system("patch -p0 < \'#{File.dirname(__FILE__)}/patches/gc.c.patch\' &> ../patch.log")
            puts "  configuring" or system("./configure --prefix=#{tmp}#{build_dir}/usr &> ../configure.log")
            puts "  making" or system("make &> ../make.log")
  
            raise "No home directory set in ENV['HOME']" unless home = ENV['HOME']
            binary_dir = "#{home}/bin"
            puts "  installing to #{binary_dir}"
            binary = "#{binary_dir}/ruby_bleak_house"
            FileUtils.cp("./ruby", binary)
            FileUtils.chmod(0755, binary)
  
            puts "  installed as #{binary}"
          end
        end
      rescue Object => e
        puts "ERROR: please see the last modified log file in #{tmp}#{build_dir}, perhaps\nit will contain a clue."
      end    
    end    
  end
end

#def check_configure_size
#  if (size = File.size("configure")) != 476155
#    raise "Configure size is wrong (got #{size})"
#  end
#end

