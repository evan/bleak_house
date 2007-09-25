
require 'lib/bleak_house/support/rake'

begin
  require 'echoe'
  
  Echoe.new("bleak_house") do |p|
    p.author = "Evan Weaver" 
    p.project = "fauna"
    p.summary = "A library for finding memory leaks."
    p.url = "http://blog.evanweaver.com/files/doc/fauna/bleak_house/"
    p.docs_host = 'blog.evanweaver.com:~/www/bax/public/files/doc/'
    p.rdoc_pattern = /^ext.*\.c|lib.*logger.*rb|analyzer|rails\/bleak_house|^README|^CHANGELOG|^TODO|^LICENSE|^COPYING$/
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
