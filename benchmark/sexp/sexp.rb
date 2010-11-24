$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'citrus'

#
# h1. Introduction
#
# This file is the facade over a Sexp grammar/parser aiming at parsing functional 
# ruby expressions of the following form:
#
#   (concat "hello " (ask "Name? ") (times "!" 3))
#
# h2. Grammar usage
#
#    require 'sexp'
#    ast = Sexp::parse("...")
#    [...]
#
# h2. Running unit tests
#
#   ruby sexp.rb test
#
# h2. Modifying the grammar and running benchmarks
#
#   # 1. ensure benchmarking on the current version
#   ruby sexp.rb bench
#
#   # 2. modify sexp.citrus or citrus itself
#   Sexp::VERSION = ...
#   [...]
#
#   # 3. test & benchmarking on the new version
#   ruby sexp.rb unit
#   ruby sexp.rb bench
#
#   # 4. Compare performances
#   ruby sexp.rb gnuplot [v1 v2 ... vn]
#
module Sexp

  # Version of this Sexp grammar
  VERSION = "1.0.2"

  # Load and evaluate the grammars contained in sexp.citrus into 
  # the global namespace.
  Citrus.load(File.expand_path('../sexp', __FILE__))
  
  # Delegated to the parser
  def self.parse(input, options = {})
    Sexp::Parser.parse(input, {:memoize => true}.merge(options))
  end
  
  # Generates an expression of a given length
  def self.generate(length = 32)
    Gen.new.list(length)
  end
  
  # Generator of Sexp expressions
  class Gen
    
    # Examples of string literals (unquoted so far)
    STRING_EXAMPLES = ["", "Hello world", "O'Neil", "Hello\nWorld", "\"Oh joy!\", he said."]
    
    # Examples of variable names
    VARIABLE_EXAMPLES = ["a", "hello", "say_hello"]
    
    # Examples of variable names
    MODULE_EXAMPLES = ["::X", "::Citrus", "Citrus::Grammar", "::Citrus::Grammar"]
    
    def flip
      Kernel.rand >= 0.5
    end
    def select(examples)
      examples[Kernel.rand(examples.size)]
    end
    
    ####################################################### high-level rules
    def expression(size)
      size <= 1 ? termexpr : list(size)
    end
    def list(size)
      args = []
      while size > 0
        got = 1 + Kernel.rand(size)
        args << expression(got)
        size -= got
      end
      "(" + args.join(', ') + ")"
    end
    def termexpr
      self.send select([:NUMERIC, :STRING, :VARIABLE, :MODULE])
    end
    
    ####################################################### numerics
    def NUMERIC
      flip ? INTEGER() : FLOAT()
    end
    def INTEGER
      (SIGN() * Kernel.rand(2**32-1)).to_s
    end
    def FLOAT
      (SIGN() * Kernel.rand*1000).to_s
    end
    def SIGN
      flip ? +1 : -1
    end
    
    ####################################################### strings
    def STRING
      flip ? SINGLE_QUOTED_STRING() : DOUBLE_QUOTED_STRING()
    end
    def SINGLE_QUOTED_STRING
      "'" + select(STRING_EXAMPLES).gsub(/([^\\])'/,%q{\1\\\'}) + "'"
    end
    def DOUBLE_QUOTED_STRING
      '"' + select(STRING_EXAMPLES).gsub('"','\"') + '"'
    end
    
    ####################################################### vars, methods, modules
    def VARIABLE
      select(VARIABLE_EXAMPLES)
    end
    def MODULE
      select(MODULE_EXAMPLES)
    end
    
  end # class Gen
  
  # Unit tests for the parser
  require 'test/unit/testcase'
  class ParserTest < Test::Unit::TestCase

    def consume(text, rule = :expression)
      Sexp::parse(text, :root => rule, :consume => true)
    end
    
    def test_expression_on_random
      assert_nothing_raised{
        consume(Sexp::generate(64), :expression)
      }
    end
  
    def test_expression
      [ %q{a}, %q{12}, %q{"hello"}, %q{(12 15)}, %q{(12, 15)},
        %q{(list 12 13 15)}, %q{(list (concat 12 13) 15)} ].each{|p|
        assert_nothing_raised{ consume(p, :expression) }
      }
    end
  
    def test_float
      [ "0.0", "+0.0", "-0.0", "12.0", "-12.0", "+12.0" ].each{|p| 
        assert_equal p.to_f, consume(p, :FLOAT).to_f
      }
    end
  
    def test_integer
      [ "0", "+0", "-0", "12", "-12", "+12", "1_000_000" ].each{|p| 
        assert_equal p.to_i, consume(p, :INTEGER).to_i
      }
    end
      
    def test_double_quoted_string
      [ %q{""}, %q{"hello"}, %q{"O\"Neil"} ].each{|p| 
        assert_nothing_raised{ consume(p, :DOUBLE_QUOTED_STRING) }
      }
    end
      
    def test_single_quoted_string
      [ %q{''}, %q{'hello'}, %q{'O\'Neil'} ].each{|p| 
        assert_nothing_raised{ consume(p, :SINGLE_QUOTED_STRING) }
      }
    end
      
    def test_variable
      [ "a", "hello", "hello_world" ].each{|p| 
        assert_nothing_raised{ consume(p, :VARIABLE) }
      }
    end
      
    def test_module
      [ "::A", "A", "Hello", "HelloWorld", "Hello::World", "::Hello::World" ].each{|p| 
        assert_nothing_raised{ consume(p, :MODULE) }
      }
    end
  
  end # class ParserTest
  
end

if $0 == __FILE__
  case (ARGV[0] || 'test').to_sym
    when :unit, :test
      require 'test/unit'
    when :bench, :benchmark
      require 'benchmark'
      require File.expand_path('../../gbench', __FILE__)
      Citrus::GBench.load("sexp.bench"){|bench|
        (1..100).each do |length|
          puts "Generating on #{length}"
          5.times do |i|
            expr = Sexp.generate(length)
            time = Benchmark.measure{ Sexp::parse(expr) }.real
            bench.report(Sexp::VERSION, length, time)
          end
        end
      }
    when :gnuplot
      require File.expand_path('../../gbench', __FILE__)
      Citrus::GBench.load("sexp.bench"){|bench|
        bench.gnuplot_compare ARGV[1..-1]
      }
    when :profile
      text = Sexp::generate(32)
      require 'profile'
      Sexp::parse(text)
  end
end
