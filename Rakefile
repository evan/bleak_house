
require 'echoe'

Echoe.new("bleak_house") do |p|
  p.author = "Evan Weaver" 
  p.project = "fauna"
  p.summary = "A library for finding memory leaks."  
  p.url = "http://blog.evanweaver.com/files/doc/fauna/bleak_house/"  
  p.docs_host = 'blog.evanweaver.com:~/www/bax/public/files/doc/'
  p.dependencies = ['ccsv >=0.1']  
  p.require_signed = true
  
  p.rdoc_pattern = /^ext.*\.c|lib.*logger.*rb|analyzer|rails\/bleak_house|^README|^CHANGELOG|^TODO|^LICENSE|^COPYING$/
  p.test_pattern = ["test/integration/*.rb", "test/unit/*.rb"]
  p.clean_pattern << "**/bleak_house*dump*"
end
