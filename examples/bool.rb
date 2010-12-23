$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'citrus'

# This file contains a small suite of tests for the grammar found in bool.citrus.
# If this file is run directly (i.e. using `ruby bool.rb') the tests will run.
# Otherwise, this file may be required by another that needs access to the Bool
# address grammars just as any other file would be.

# Load and evaluate the grammars contained in bool.citrus into the global
# namespace.
Citrus.load(File.expand_path('../bool', __FILE__))

if $0 == __FILE__
  require 'test/unit'

  class BoolTest < Test::Unit::TestCase
    
    def consume(text, rule = :expression)
      Bool.parse(text, :root => rule, :consume => true).value
    end
    
    def test_literal
      assert_equal [:literal, true], consume("true", :literal)
      assert_equal [:literal, false], consume("false", :literal)
    end
    
    def test_parenthesed
      assert_equal [:literal, true], consume("(true)", :parenthesed)
    end
    
    def test_term_expression
      assert_equal [:proposition, "a"], consume("a", :term_expression)
      assert_equal [:literal, true], consume("true", :term_expression)
    end
    
    def test_and
      assert_equal [:and, [:literal, true], [:proposition, "b"]], consume("true and b", :and)
      assert_equal [:and, [:proposition, "a"], [:proposition, "b"]], consume("a and b", :and)
    end
    
    def test_or
      assert_equal [:or, [:literal, true], [:proposition, "b"]], consume("true or b", :or)
      assert_equal [:or, [:proposition, "a"], [:proposition, "b"]], consume("a or b", :or)
    end
    
    def test_not
      assert_equal [:not, [:literal, true]], consume("not(true)", :not)
      assert_equal [:not, [:proposition, "a"]], consume("not(a)", :not)
    end
    
    def test_proposition
      assert_equal [:proposition, "a"], consume("a", :proposition)
      assert_equal [:proposition, "m_plus"], consume("m_plus", :proposition)
    end
    
    def test_proposition_robustness
      assert_equal [:proposition, "truehistory"], consume("truehistory", :proposition)
      assert_raise(Citrus::ParseError){ consume("true", :proposition) }
      assert_raise(Citrus::ParseError){ consume("not", :proposition) }
    end
    
    def test_parenthesed_robustness
      assert_equal [:literal, true], consume("( true ) ", :parenthesed)
    end
    
    def test_eof
      #assert_equal "", consume("", :EOF)
      assert_raise(Citrus::ParseError){ consume("true", :EOF) }
    end

    def test_expression_precedence_1 
      expr = "not a or b"
      expected = [:or, [:not, [:proposition, "a"]], [:proposition, "b"]]
      assert_equal expected, consume(expr)
    end

    def test_expression_precedence_2
      expr = "a or not b"
      expected = [:or, [:proposition, "a"], [:not, [:proposition, "b"]]]
      assert_equal expected, consume(expr)
    end
    
    def test_expression_precedence_3
      expr = "a and b or c"
      expected = [:or, [:and, [:proposition, "a"], [:proposition, "b"]], [:proposition, "c"]]
      assert_equal expected, consume(expr)
    end
    
    def test_expression_precedence_4
      expr = "a or b and c"
      expected = [:or, [:proposition, "a"], [:and, [:proposition, "b"], [:proposition, "c"]]]
      assert_equal expected, consume(expr)
    end
    
    def test_expression_precedence_5
      expr = "a or b or c"
      expected = [:or, [:proposition, "a"], [:or, [:proposition, "b"], [:proposition, "c"]]]
      assert_equal expected, consume(expr)
    end
    
    def test_expression_precedence_6
      expr = "a and b and c"
      expected = [:and, [:proposition, "a"], [:and, [:proposition, "b"], [:proposition, "c"]]]
      assert_equal expected, consume(expr)
    end
    
  end
end
