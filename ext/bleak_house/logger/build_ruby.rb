
if RUBY_PLATFORM =~ /win32|windows/
  raise "Windows is not supported."
end

source_dir = File.expand_path(File.dirname(__FILE__)) + "/../../../ruby"
tmp = "/tmp/"

require 'fileutils'

if `which ruby-bleak-house` =~ /no ruby-bleak-house in/
  
  Dir.chdir(tmp) do
    build_dir = "bleak_house"
    binary_dir = File.dirname(`which ruby`)
    FileUtils.rm_rf(build_dir) rescue nil
    Dir.mkdir(build_dir)
  
    begin
      Dir.chdir(build_dir) do
  
        # Copy Ruby source
        bz2 = "ruby-1.8.6.tar.bz2"
        FileUtils.copy "#{source_dir}/#{bz2}", bz2
  
        # Extract
        system("tar xjf #{bz2} > tar.log 2>&1")
        File.delete bz2
    
        Dir.chdir("ruby-1.8.6") do
  
          # Patch
          system("patch -p0 < \'#{source_dir}/gc.c.patch\' > ../gc.c.patch.log 2>&1")
          system("patch -p0 < \'#{source_dir}/parse.y.patch\' > ../parse.y.patch.log 2>&1")
  
          # Configure
          system("./configure --prefix=#{binary_dir[0..-5]} > ../configure.log 2>&1") # --with-static-linked-ext
  
          # Make
          system("make > ../make.log 2>&1")
  
          binary = "#{binary_dir}/ruby-bleak-house"
  
          # Install binary
          if File.exist? "ruby"        
            # Avoid "Text file busy" error
            exec("rm #{binary}; cp ./ruby #{binary}; chmod 755 #{binary}")
          else
            raise "Binary did not build"
          end
        end
        
      end
    rescue Object => e
      raise "Please see the last modified log file in #{tmp}#{build_dir}, perhaps\nit will contain a clue.\n#{e.to_s}"
    end
    
    # Success
  end    
  
end