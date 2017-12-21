require './lexer.rb'
require './parser.rb'
require './executor.rb'
require "awesome_print"

class Hello
  def world(x)
    "X: #{x}"
  end
end

script = File.read('test2.js')
executor = SimpleLanguage::Executor.new
hello = Hello.new
executor.register('world', hello, :world)
output = executor.run(script)
puts output
