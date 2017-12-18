require './lexer.rb'

program = File.read('test1.js')
tokens = SimpleLanguage::lex(program)
puts tokens
