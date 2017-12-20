require './lexer.rb'
require './parser.rb'
require './executor.rb'
require "awesome_print"

script = File.read('test2.js')
executor = SimpleLanguage::Executor.new
output = executor.run(script)
puts output
