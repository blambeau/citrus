$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'citrus'

module Sexp

  # Load and evaluate the grammars contained in sexp.citrus into 
  # the global namespace.
  Citrus.load(File.expand_path('../sexp', __FILE__))
  
end