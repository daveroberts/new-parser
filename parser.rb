require "awesome_print"
require "pry"

module SimpleLanguage
  def self.parse(tokens)
    ast, rest = make_program(tokens.dup)
    return ast
  end

  def self.make_program(tokens)
    rest = tokens
    statements = []
    while rest && rest.length > 0
      statement, rest = make_statement(rest.dup)
      if !statement
        raise Exception, "Could not make a statement" if !statement
      end
      statements.push(statement)
    end
    return statements, rest
  end

  def self.make_statement(tokens)
    tokens_orig = tokens.dup
    assignment, rest = make_assignment(tokens.dup)
    return assignment, rest if assignment
    expr, rest = make_expression(tokens.dup)
    return expr, rest if expr
    ref, rest = make_reference(tokens.dup)
    return ref, rest if ref
    return nil, tokens
  end

  def self.make_assignment(tokens)
    to, rest = make_reference(tokens.dup)
    return nil, tokens if !to
    return nil, tokens if rest[0] && rest[0][:type] != :equals
    rest.shift
    from, rest = make_expression(rest.dup)
    return nil, tokens if !from
    return {action: :assign, from: from, to: to}, rest
  end

  def self.make_expression(tokens)
    term, rest = make_term(tokens.dup)
    return nil, tokens if !term
    if rest[0] && rest[0][:type] == :plus
      rest.shift
      expr, rest = make_expression(rest.dup)
      return {action: :add, left: term, right: expr},rest if expr
      raise Exception, "Trying to add a non-expression"
    elsif rest[0] && rest[0][:type] == :minus
      rest.shift
      expr, rest = make_expression(rest.dup)
      return {action: :subtract, left: term, right: expr},rest if expr
      raise Exception, "Trying to subtract a non-expression"
    else
      return term, rest
    end
  end

  def self.make_term(tokens)
    factor, rest = make_factor(tokens.dup)
    return nil, tokens if !factor
    if rest[0] && rest[0][:type] == :multiply
      rest.shift
      expr, rest = make_expression(rest.dup)
      return {action: :multiply, left: factor, right: expr}, rest if expr
      raise Exception, "Trying to multiply a non-expression"
    elsif rest[0] && rest[0][:type] == :divide
      rest.shift
      expr, rest = make_expression(rest.dup)
      return {action: :divide, left: factor, right: expr}, rest if expr
      raise Exception, "Trying to divide a non-expression"
    else
      return factor, rest
    end
  end

  def self.make_factor(tokens)
    if tokens[0] && tokens[0][:type] == :left_paren
      tokens.shift
      expr, rest = make_expression(tokens.dup)
      raise Exception, "Invalid expression after (" if !expr
      raise Exception, "`(` without `)`" if rest[0][:type] != :right_paren
      rest.shift
      return { action: :grouping, expression: expr }, rest
    end
    num, rest = make_number(tokens.dup)
    return num, rest if num
    str, rest = make_string(tokens)
    return str, rest if str
    hash, rest = make_hash_literal(tokens)
    return hash, rest if hash
    ref, rest = make_reference(tokens.dup)
    return ref, rest if ref
    return nil, tokens
    #if @tokens[@position][:type] == :left_paren
    #  @position = @position + 1
    #  expr = make_expression
    #  if @tokens[@position][:type] == :right_paren
    #    return "("+expr+")"
    #    @position = @position + 1
    #  else
    #    raise Exception, "Unmatched parenthesis"
    #  end
    #else
    #  numb = make_number
    #end
  end

  def self.make_number(tokens)
    if tokens[0] && tokens[0][:type] == :number
      number = tokens[0][:value]
      tokens.shift
      return {action: :number, value: number}, tokens
    else
      return nil, tokens
    end
  end

  def self.make_string(tokens)
    rest = tokens.dup
    return nil, tokens if !rest[0] || rest[0][:type] != :string
    str = rest[0][:value]
    rest.shift
    return {type: :string, value: str}, rest
  end
  
  def self.make_hash_literal(tokens)
    rest = tokens.dup
    return nil, tokens if !rest[0] || rest[0][:type] != :left_curly
    rest.shift #left curly
    members = {}
    while rest[0] && rest[0][:type] != :right_curly
      raise Exception, "Invalid hash literal" if rest[0][:type] != :symbol
      symbol = rest[0][:value]
      symbol = symbol.to_sym
      rest.shift
      rhs, rest = make_expression(rest)
      raise Exception, "Invalid hash map value" if !rhs
      members[symbol] = rhs
      rest.shift if rest[0] && rest[0][:type] == :comma
    end
    rest.shift # right curly
    return { type: :hash_literal, value: members }, rest
  end

  def self.make_reference(tokens)
    if !tokens[0] || tokens[0][:type] != :identifier
      return nil, tokens
    end
    ident = tokens[0][:value]
    tokens.shift
    rest = tokens.dup
    matched_any = false
    chains = []
    while true do
      matched_any = false
      if rest[0] && rest[0][:type] == :left_bracket
        matched_any = true
        rest.shift
        ind, rest = make_expression(rest.dup)
        raise Exception, "Invalid array index" if !ind
        if !rest[0] || rest[0][:type] != :right_bracket
          raise Exception, "Left bracket without right bracket"
        end
        rest.shift
        chains.push({type: :index_of, index: ind})
      elsif rest[0] && rest[0][:type] == :left_paren
        rest.shift # left paren
        matched_any = true
        params = []
        while rest[0] && rest[0][:type] != :right_paren do
          expr, rest = make_expression(rest.dup)
          raise Exception, "Invalid parameter" if !expr
          if rest[0] && (rest[0][:type] != :comma && rest[0][:type] != :right_paren)
            raise Exception, "Invalid parameters to function call"
          end
          params.push(expr)
          rest.shift if rest[0] && rest[0][:type] == :comma
        end
        rest.shift if rest[0] && rest[0][:type] == :right_paren
        chains.push({type: :function_params, params: params})
      elsif rest[0] && rest[0][:type] == :dot
        matched_any = true
        rest.shift
        raise Exception, "Must have identifier after ." if !rest[0] || rest[0][:type] != :identifier
        member = rest[0][:value]
        rest.shift
        chains.push({type: :member, member: member})
      end
      break if !matched_any
    end
    return {action: :reference, value: ident, chains: chains }, rest
  end

end
