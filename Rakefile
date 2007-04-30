require 'rubygems'
require 'rake'
require 'lib/bleak_house/rake_task_redefine_task'

NAME = "bleak_house"

begin
  require 'rake/clean'
  gem 'echoe', '>= 1.1'
  require 'echoe'
  require 'fileutils'

  AUTHOR = "Evan Weaver"
  EMAIL = "evan at cloudbur dot st"
  DESCRIPTION = "BleakHouse is a Rails plugin for finding memory leaks. It tracks ObjectSpace for your entire app, and produces charts of references by controller, by action, and by object class."
  CHANGES = `cat CHANGELOG`[/^([\d\.]+\. .*)/, 1]
  RUBYFORGE_NAME = "fauna"
  GEM_NAME = "bleak_house" 
  HOMEPATH = "http://blog.evanweaver.com"
  RELEASE_TYPES = ["gem"]
  REV = nil
  VERS = `cat CHANGELOG`[/^([\d\.]+)\. /, 1]
  CLEAN.include ['**/.*.sw?', '*.gem', '.config']
  RDOC_OPTS = ['--quiet', '--title', "bleak_house documentation", "--opname", "index.html", "--line-numbers", "--main", "README", "--inline-source"]
  
  include FileUtils
  
  taskmsg = File.open(File.dirname(__FILE__) + "/tasks/bleak_house_tasks.rake").readlines
  taskmsg = taskmsg[0..3] + [taskmsg[7][2..-1]] + taskmsg[9..-1]
  
  echoe = Echoe.new(GEM_NAME, VERS) do |p|
    p.author = AUTHOR 
    p.rubyforge_name = RUBYFORGE_NAME
    p.name = NAME
    p.description = DESCRIPTION
    p.changes = CHANGES
    p.email = EMAIL
    p.summary = DESCRIPTION
    p.url = HOMEPATH
    p.need_tar = false
    p.need_tar_gz = true
    p.test_globs = ["*_test.rb"]
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
