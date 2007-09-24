
class Array
  alias :time :first
  alias :data :last
  
  def sum
    inject(0) {|s, x| x + s}
  end
  
  def to_i
    self.map{|s| s.to_i}
  end
    
end

class Dir
  def self.descend path, &block
    path = path.split("/") unless path.is_a? Array
    top = (path.shift or ".")
    Dir.mkdir(top) unless File.exists? top
    Dir.chdir(top) do
      if path.any?
        descend path, &block
      else
        block.call
      end
    end
  end
end

class String
  def to_filename
    self.downcase.gsub(/[^\w\d\-]/, '_')
  end
end

class NilClass
  def +(op)
    self.to_i + op
  end
end
 
class Symbol
  def =~ regex
    self.to_s =~ regex
  end
  def [](*args)
    self.to_s[*args]
  end
end