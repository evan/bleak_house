
if RUBY_PLATFORM =~ /win32|windows/
  puts "ERROR: windows not supported."
  exit
end

require 'fileutils'
puts "Building patched Ruby binary"

tmp = "/tmp/"
Dir.chdir(tmp) do

  build_dir = "bleak_house"
  binary_dir = File.dirname(`which ruby`)
  FileUtils.rm_rf(build_dir) rescue nil
  Dir.mkdir(build_dir)

  begin
    Dir.chdir(build_dir) do
      puts "  Downloading Ruby source"
      bz2 = "ruby-1.8.6.tar.bz2"
      system("wget 'http://rubyforge.org/frs/download.php/18434/ruby-1.8.6.tar.bz2' &> wget.log")
      puts "  Extracting"
      system("tar xjf #{bz2} &> tar.log")
      File.delete bz2
  
      Dir.chdir("ruby-1.8.6") do
        puts "  Patching"
        system("patch -p0 < \'#{File.dirname(__FILE__)}/../../../patches/gc.c.patch\' &> ../gc.c.patch.log")
        system("patch -p0 < \'#{File.dirname(__FILE__)}/../../../patches/parse.y.patch\' &> ../parse.y.patch.log")
        puts "  Configuring"
        system("./configure --prefix=#{binary_dir[0..-5]} &> ../configure.log") # --with-static-linked-ext
        puts "  Making"
        system("make &> ../make.log")

        binary = "#{binary_dir}/ruby-bleak-house"
        puts "  Installing as #{binary}"

        # Avoid a "Text file busy" error
        exec("cp ./ruby #{binary}; chmod -755 #{binary}; echoe \"  Done\"")
      end
      
    end
  rescue Object => e
    puts "ERROR: please see the last modified log file in #{tmp}#{build_dir}, perhaps\nit will contain a clue.\n#{e.to_s}"
  end
    
end    

