require 'mkmf'
$CFLAGS = ENV['CFLAGS']
dir_config('snapshot')
create_makefile('snapshot')
