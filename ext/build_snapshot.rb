RUBY_VERSION = `ruby -v`.split(" ")[1]
require 'mkmf'
$CFLAGS = ENV['CFLAGS']
dir_config('snapshot')
create_makefile('snapshot')
