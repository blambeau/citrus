$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'citrus'

# This file contains a small suite of tests for the grammar found in sexp.citrus.
# If this file is run directly (i.e. using `ruby sexp.rb') the tests will run.
# Otherwise, this file may be required by another that needs access to the Bool
# address grammars just as any other file would be.

# Load and evaluate the grammars contained in sexp.citrus into the global
# namespace.
Citrus.load(File.expand_path('../sexp', __FILE__))

if $0 == __FILE__
  require 'test/unit'

  class SexpTest < Test::Unit::TestCase

    def consume(text, rule = :expression)
      Sexp.parse(text, :root => rule, :consume => true)
    end
    
    def test_expression
      [ 
        %q{a},
        %q{12},
        %q{"hello"},
        %q{(list 12 13 15)},
        %q{(list (concat 12 13) 15)},
      ].each{|p|
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
      [ %q{""}, 
        %q{"hello"},
        %q{"O\"Neil"}
      ].each{|p| 
        assert_nothing_raised{ consume(p, :DOUBLE_QUOTED_STRING) }
      }
    end
    
    def test_single_quoted_string
      [ %q{''}, 
        %q{'hello'},
        %q{'O\'Neil'}
      ].each{|p| 
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
    
  end
end