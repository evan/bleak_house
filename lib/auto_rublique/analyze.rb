
require 'rubygems'

require 'gruff'

begin 
  require 'fjson'
rescue LoadError
  require 'json'
end

class AutoRublique
  class Analyze
    
    def initialize(source_data, name, dir)
      @source_data = source_data
      @order = order
      @namespace = namespace      
    end 
    
    def build
    
    end
    
    def self.build_all(filename)
      unless File.exists? filename
        puts "No data file found: #{filename}"
        exit 
      end
      
      data = JSON.parse(File.open(filename).read)
      # find toplevel namespace
      require 'breakpoint'; breakpoint
      
      Analyze.
      # find and flatten all sublevel namespaces
    
    end
 
  end
end