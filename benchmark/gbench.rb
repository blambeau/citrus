require 'tempfile'
module Citrus
  class GBench
    
    # Dedicated hash for timing measures
    class Measures
  
      def initialize
        @measures = Hash.new
      end
  
      def sum(array)
        array.inject(0){|m, x| m + x}
      end
  
      def mean(array)
        sum(array).to_f / array.size
      end
  
      def [](length)
        @measures[length] ||= []
      end
  
      def []=(length, value)
        self[length] << value
      end
  
      def to_gnuplot_data
        @measures.keys.sort.collect{|l|
          "#{l} #{mean(self[l])}"
        }.join("\n")
      end
      
    end # class Measures
      
    attr_reader :name  
      
    def initialize(name)
      @name = name
      @measures = Hash.new
    end
    
    def report(version, size, time)
      self[version][size] = time
    end
    
    def [](version)
      @measures[version] ||= Measures.new
    end
    
    def self.load(file)
      bench = if ::File.exists?(file)
        Marshal::load(::File.read(file))
      else
        GBench.new(::File.basename(file, '.bench'))
      end
      if block_given?
        yield(bench) 
        bench.save(file)
      end
      bench
    end
    
    def save(file)
      if file.is_a?(IO)
        file << Marshal::dump(self)
      else
        ::File.open(file, "w"){|io| save(io)}
      end
    end
    
    def gnuplot_compare
      keys = @measures.keys.sort
      keys.each{|v| 
        ::File.open("#{name}.#{v}.dat", "w"){|io|
          io << self[v].to_gnuplot_data
        }
      }
      
      fittings = []
      keys.each_with_index{|version,index|
        fittings << <<-EOF
          f#{index}(x) = a#{index}*x*x + b#{index}*x + c#{index}
          a#{index} = 0.5
          b#{index} = 0.5
          c#{index} = 0.5
          fit f#{index}(x) '#{name}.#{version}.dat' using 1:2 via a#{index}, b#{index}, c#{index}
        EOF
      }
      
      plots = []
      keys.each_with_index{|version, index|
        plots << <<-EOF.strip
          a#{index}*x*x + b#{index}*x + c#{index} title 'fitting #{version}'
        EOF
        plots << <<-EOF.strip
          '#{name}.#{version}.dat' using 1:2 title '#{name} #{version}'
        EOF
      }
      
      ::File.open("#{name}.gnuplot", 'w'){|f|
        f << <<-EOF
          set terminal png
          set output "#{name}.png"
          set xlabel "Length of input"
          set ylabel "CPU time to parse"
          #{fittings.join("\n")}
          plot #{plots.join(", ")}
        EOF
      }
      `gnuplot #{name}.gnuplot`
    end
      
  end # class GBench
end # module Citrus