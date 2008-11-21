
# Extension abuse in order to build our patched binary as part of the gem install process.

if RUBY_PLATFORM =~ /win32|windows/
  raise "Windows is not supported."
end

unless RUBY_VERSION == '1.8.6'
  raise "Wrong Ruby version, you're at '#{RUBY_VERSION}', need 1.8.6"
end

source_dir = File.expand_path(File.dirname(__FILE__)) + "/../ruby"
tmp = "/tmp/"

require 'fileutils'
require 'rbconfig'

def which(basename)
  # system('which') is not compatible across Linux and BSD
  ENV['PATH'].split(File::PATH_SEPARATOR).detect do |directory|
    path = File.join(directory, basename.to_s)
    path if File.exist? path
  end
end

if which('ruby-bleak-house') and
  `ruby-bleak-house -e "puts RUBY_PATCHLEVEL"`.to_i >= 902
  # OK
else
  # Build
  Dir.chdir(tmp) do
    build_dir = "bleak_house"
    binary_dir = File.dirname(`which ruby`)

    FileUtils.rm_rf(build_dir) rescue nil
    if File.exist? build_dir
      raise "Could not delete previous build dir #{Dir.pwd}/#{build_dir}"
    end

    Dir.mkdir(build_dir)

    begin
      Dir.chdir(build_dir) do

        # Copy Ruby source
        bz2 = "ruby-1.8.6-p230.tar.bz2"
        FileUtils.copy "#{source_dir}/#{bz2}", bz2

        # Extract
        system("tar xjf #{bz2} > tar.log 2>&1")
        File.delete bz2

        Dir.chdir("ruby-1.8.6-p230") do

          # Patch, configure, and build
          ["valgrind", "configure", "gc"].each do |patch|
            system("patch -p0 < \'#{source_dir}/#{patch}.patch\' > ../#{patch}_patch.log 2>&1")
          end

          system("./configure --prefix=#{binary_dir[0..-5]} > ../configure.log 2>&1") # --with-static-linked-ext

          # Patch the makefile for arch/sitedir
          makefile = File.read('Makefile')
          %w{arch sitearch sitedir}.each do | key |
            makefile.gsub!(/#{key} = .*/, "#{key} = #{Config::CONFIG[key]}")
          end
          File.open('Makefile', 'w'){|f| f.puts(makefile)}

          # Patch the config.h for constants
          constants = {
            'RUBY_LIB' => 'rubylibdir',          #define RUBY_LIB "/usr/lib/ruby/1.8"
            'RUBY_SITE_LIB' => 'sitedir',        #define RUBY_SITE_LIB "/usr/lib/ruby/site_ruby"
            'RUBY_SITE_LIB2' => 'sitelibdir',    #define RUBY_SITE_LIB2 "/usr/lib/ruby/site_ruby/1.8"
            'RUBY_PLATFORM' => 'arch',           #define RUBY_PLATFORM "i686-linux"
            'RUBY_ARCHLIB' => 'topdir',          #define RUBY_ARCHLIB "/usr/lib/ruby/1.8/i686-linux"
            'RUBY_SITE_ARCHLIB' => 'sitearchdir' #define RUBY_SITE_ARCHLIB "/usr/lib/ruby/site_ruby/1.8/i686-linux"
          }
          config_h = File.read('config.h')
          constants.each do | const, key |
            config_h.gsub!(/#define #{const} .*/, "#define #{const} \"#{Config::CONFIG[key]}\"")
          end
          File.open('config.h', 'w'){|f| f.puts(config_h)}

          system("make > ../make.log 2>&1")

          binary = "#{binary_dir}/ruby-bleak-house"

          # Install binary
          if File.exist? "ruby"
            # Avoid "Text file busy" error
            File.delete binary if File.exist? binary
            exec("cp ./ruby #{binary}; chmod 755 #{binary}")
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
