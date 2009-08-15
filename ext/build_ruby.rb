
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

def execute(command)    
  puts command
  unless system(command)
    puts "Failed: #{command.inspect}"
    exit -1 
  end
end

def which(basename)
  # execute('which') is not compatible across Linux and BSD
  ENV['PATH'].split(File::PATH_SEPARATOR).detect do |directory|
    path = File.join(directory, basename.to_s)
    path if File.exist? path
  end
end

if which('ruby-bleak-house') and
  (patchlevel  = `ruby-bleak-house -e "puts RUBY_PATCHLEVEL"`.to_i) >= 903
  puts "** Binary `ruby-bleak-house` is already available (patchlevel #{patchlevel})"
else
  # Build
  Dir.chdir(tmp) do
    build_dir = "bleak_house"

    FileUtils.rm_rf(build_dir) rescue nil
    if File.exist? build_dir
      raise "Could not delete previous build dir #{Dir.pwd}/#{build_dir}"
    end

    Dir.mkdir(build_dir)

    begin
      Dir.chdir(build_dir) do

        puts "** Copy Ruby source"
        bz2 = "ruby-1.8.6-p286.tar.bz2"
        FileUtils.copy "#{source_dir}/#{bz2}", bz2

        puts "** Extract"
        execute("tar xjf #{bz2}")
        File.delete bz2

        Dir.chdir("ruby-1.8.6-p286") do

          puts "** Patch Ruby"
          execute("patch -p0 < '#{source_dir}/ruby.patch'")

	  puts "** Determining OpenSSL version"
	  cmd = open("|openssl version")
	  openssl_version_string = cmd.gets
	  cmd.close

          if openssl_version_string.nil?
	    puts "** Could not determine openssl version, skipping patches"
	  else
	    openssl_version = openssl_version_string.split(/\s/)[1]
	    if openssl_version >= "0.9.8j"
	      puts "** Applying openssl patches to build against #{openssl_version_string}"
	      execute( "patch -p3 < '#{source_dir}/ruby-1.8.6-openssl.patch'")
	    else
	      puts "** No patching need for #{openssl_version_string}"
	    end
	  end

          env = Config::CONFIG.map do |key, value|
            "#{key}=#{value.inspect}" if key.upcase == key and value
          end.compact.join(" ")            

          puts "** Configure"
          execute("env #{env} ./configure #{Config::CONFIG['configure_args']}".sub("'--enable-shared'", ""))

          puts "Patch Makefile"
          # FIXME Why is this necessary?
          makefile = File.read('Makefile')
          %w{arch sitearch sitedir}.each do | key |
            makefile.gsub!(/#{key} = .*/, "#{key} = #{Config::CONFIG[key]}")
          end
          File.open('Makefile', 'w'){|f| f.puts(makefile)}

          puts "Patch config.h"
          constants = {
            'RUBY_LIB' => 'rubylibdir',
            'RUBY_SITE_LIB' => 'sitedir',
            'RUBY_SITE_LIB2' => 'sitelibdir',
            'RUBY_PLATFORM' => 'arch',
            'RUBY_ARCHLIB' => 'topdir',
            'RUBY_SITE_ARCHLIB' => 'sitearchdir'
          }
          config_h = File.read('config.h')
          constants.each do | const, key |
            config_h.gsub!(/#define #{const} .*/, "#define #{const} \"#{Config::CONFIG[key]}\"")
          end
          File.open('config.h', 'w') do |f| 
            f.puts(config_h)
          end
          
          puts "** Make"
          execute("env #{env} make")

          bleak_binary = "#{Config::CONFIG['bindir']}/ruby-bleak-house"
          ruby_binary = Config::CONFIG["RUBY_INSTALL_NAME"] || "ruby"

          puts "** Install binary"
          if File.exist? ruby_binary
            # Avoid "Text file busy" error
            File.delete bleak_binary if File.exist? bleak_binary
            exec("cp ./#{ruby_binary} #{bleak_binary}; chmod 755 #{bleak_binary}")
          else
            raise
          end
        end

      end
    end

    puts "Success"
  end

end
