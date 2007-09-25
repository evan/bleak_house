
require 'lib/bleak_house/support/rake'

begin
  require 'echoe'
  
  Echoe.new("bleak_house") do |p|
    p.author = "Evan Weaver" 
    p.project = "fauna"
    p.summary = "A library for finding memory leaks."
    p.url = "http://blog.evanweaver.com/files/doc/fauna/bleak_house/"
    p.docs_host = 'blog.evanweaver.com:~/www/bax/public/files/doc/'
    p.rdoc_pattern = /^tasks|analyze|bleak_house\/bleak_house\.rb|c\.rb|^README|^CHANGELOG|^TODO|^LICENSE$/
    p.dependencies = ['rake']
    p.require_signed = true
    p.include_gemspec = false
    p.include_rakefile = true      
  end
         
rescue LoadError
end

desc 'Run tests.'
Rake::Task.redefine_task("test") do
  system "ruby-bleak-house -Ibin:lib:test test/unit/test_bleak_house.rb #{ENV['METHOD'] ? "--name=#{ENV['METHOD']}" : ""}"
end

desc 'Build a patched binary.'
namespace :ruby do
  task :build do    
    if RUBY_PLATFORM =~ /win32|windows/
      puts "ERROR: windows not supported."
      exit
    end
    require 'fileutils'
    puts "building patched Ruby binary"
    tmp = "/tmp/"
    Dir.chdir(tmp) do
      build_dir = "bleak_house"
      binary_dir = File.dirname(`which ruby`)
      FileUtils.rm_rf(build_dir) rescue nil
      Dir.mkdir(build_dir)
      begin
        Dir.chdir(build_dir) do
          puts "  downloading Ruby source"
          bz2 = "ruby-1.8.6.tar.bz2"
          system("wget 'http://rubyforge.org/frs/download.php/18434/ruby-1.8.6.tar.bz2' &> wget.log")
          puts "  extracting"
          system("tar xjf #{bz2} &> tar.log")
          File.delete bz2
          Dir.chdir("ruby-1.8.6") do
            puts "  patching"
            system("patch -p0 < \'#{File.dirname(__FILE__)}/patches/gc.c.patch\' &> ../gc.c.patch.log")
            system("patch -p0 < \'#{File.dirname(__FILE__)}/patches/parse.y.patch\' &> ../parse.y.patch.log")
            puts "  configuring"
            system("./configure --prefix=#{binary_dir[0..-5]} &> ../configure.log") # --with-static-linked-ext
            puts "  making"
            system("make &> ../make.log")
  
            binary = "#{binary_dir}/ruby-bleak-house"
            puts "  installing as #{binary}"
            FileUtils.cp("./ruby", binary)
            FileUtils.chmod(0755, binary)
            puts "  done"
          end
        end
      rescue Object => e
        puts "ERROR: please see the last modified log file in #{tmp}#{build_dir}, perhaps\nit will contain a clue."
      end    
    end    
  end
end

