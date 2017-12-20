# program := { <statement> }
def make_program(str)
  statement = make_statement(str)
  
end
# statement := <assignment> | <func_call> | <index_of>
# assignment := <identifier> { <ws> } <equals> { <ws> } <string>
# underscore := _
# ws := <space> | <tab>
# equals := =
# string := <double_quote> { <non_double_quote> } <double_quote>
# func_call := <identifier> <left_parenthesis> <expr> <right_parenthesis>
# left_parenthesis := (
# right_parenthesis := )
# index_of := <identifier> <left_bracket> <expr> <right_bracket>
