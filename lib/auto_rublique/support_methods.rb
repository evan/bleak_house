
class Array
  alias :time :first
  alias :data :last
  
  def sum
    inject(0) {|s, x| s + x}
  end
    
end

class Dir
  def self.descend path, &block
    path = path.split("/") unless path.is_a? Array
    top = path.shift
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
