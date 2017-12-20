require './lexer.rb'
require './parser.rb'
require "awesome_print"

program = File.read('test2.js')
tokens = SimpleLanguage::lex(program)
ast = SimpleLanguage::parse(tokens)
ap ast
