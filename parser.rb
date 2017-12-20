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
    for_block, rest = make_for(tokens)
    return for_block, rest if for_block
    if_block, rest = make_if(tokens)
    return if_block, rest if if_block
    expr, rest = make_expression(tokens.dup)
    return expr, rest if expr
    ref, rest = make_reference(tokens.dup)
    return ref, rest if ref
    return nil, tokens
  end

  def self.make_for(tokens)
    rest = tokens.dup
    return nil, tokens if !rest[0] || rest[0][:type] != :identifier || (rest[0][:value] != 'for' && rest[0][:value] != 'foreach')
    rest.shift # for
    raise Exception, "for requires identifier" if !rest[0] || rest[0][:type] != :identifier
    singular = rest[0][:value]
    rest.shift # singular
    raise Exception, "for requires in" if !rest[0] || rest[0][:type] != :identifier || rest[0][:value] != 'in'
    rest.shift # in
    plural, rest = make_expression(rest)
    raise Exception, "for requires a group" if !plural
    raise Exception, "for requires block" if !rest[0] || rest[0][:type] != :left_curly
    rest.shift # left curly
    block = []
    while rest[0] && rest[0][:type] != :right_curly
      statement, rest = make_statement(rest)
      raise Exception, "Invalid statement in for block" if !statement
      block.push(statement)
    end
    raise Exception, "For block must end with `}`" if !rest[0] || rest[0][:type] != :right_curly
    rest.shift # Right curly
    return {type: :for, singular: singular, plural: plural, block: block}, rest
  end

  def self.make_if(tokens)
    rest = tokens.dup
    return nil, tokens if !rest[0] || rest[0][:type] != :identifier || rest[0][:value] != 'if'
    rest.shift # if
    condition, rest = make_expression(rest)
    raise Exception, "if requires condition" if !condition
    raise Exception, "if requires block" if !rest[0] || rest[0][:type] != :left_curly
    rest.shift # left curly
    block = []
    while rest[0] && rest[0][:type] != :right_curly
      statement, rest = make_statement(rest)
      raise Exception, "Invalid statement in if block" if !statement
      block.push(statement)
    end
    raise Exception, "Block must end with `}`" if !rest[0] || rest[0][:type] != :right_curly
    rest.shift # Right curly
    return {type: :if, condition: condition, block: block}, rest
  end

  def self.make_assignment(tokens)
    to, rest = make_reference(tokens.dup)
    return nil, tokens if !to
    return nil, tokens if rest[0] && rest[0][:type] != :equals
    rest.shift
    from, rest = make_expression(rest.dup)
    return nil, tokens if !from
    return {action: :assign, to: to, from: from}, rest
  end

  def self.make_expression(tokens)
    rest = tokens.dup
    comp, rest = make_comparison(rest)
    return nil, tokens if !comp
    if rest[0] && rest[0][:type] == :greater_than
      rest.shift # sym
      expr, rest = make_expression(rest)
      raise Exception, "Invalid expression after >" if !expr
      return {type: :greater_than, left: comp, right: expr},rest if expr
    else
      return comp, rest
    end
  end

  def self.make_comparison(tokens)
    rest = tokens.dup
    term, rest = make_term(rest)
    return nil, tokens if !term
    if rest[0] && rest[0][:type] == :plus
      rest.shift
      expr, rest = make_comparison(rest.dup)
      return {action: :add, left: term, right: expr},rest if expr
      raise Exception, "Trying to add a non-expression"
    elsif rest[0] && rest[0][:type] == :minus
      rest.shift
      expr, rest = make_comparison(rest.dup)
      return {action: :subtract, left: term, right: expr},rest if expr
      raise Exception, "Trying to subtract a non-expression"
    else
      return term, rest
    end
  end

  def self.make_term(tokens)
    rest = tokens.dup
    factor, rest = make_factor(rest)
    return nil, tokens if !factor
    if rest[0] && rest[0][:type] == :multiply
      rest.shift #sym
      expr, rest = make_term(rest)
      raise Exception, "* without expression on rhs" if !expr
      return {type: :multiply, left: factor, right: expr}, rest
    elsif rest[0] && rest[0][:type] == :divide
      rest.shift #sym
      expr, rest = make_term(rest)
      raise Exception, "/ without expression on rhs" if !expr
      return {type: :divide, left: factor, right: expr}, rest
    else
      return factor, rest
    end
  end

  def self.make_factor(tokens)
    rest = tokens.dup
    if rest[0] && rest[0][:type] == :left_paren
      rest.shift # left_paren
      expr, rest = make_expression(rest)
      raise Exception, "Invalid expression after (" if !expr
      raise Exception, "`(` without `)`" if rest[0][:type] != :right_paren
      rest.shift # right paren
      return { action: :grouping, expression: expr }, rest
    end
    num, rest = make_number(rest)
    return num, rest if num
    str, rest = make_string(rest)
    return str, rest if str
    hash, rest = make_hash_literal(rest)
    return hash, rest if hash
    arr, rest = make_array_literal(rest)
    return arr, rest if arr
    ref, rest = make_reference(rest)
    return ref, rest if ref
    return nil, tokens
  end

  def self.make_number(tokens)
    rest = tokens.dup
    if rest[0] && rest[0][:type] == :number
      number = rest[0][:value]
      rest.shift # number
      return {action: :number, value: number}, rest
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

  def self.make_array_literal(tokens)
    rest = tokens.dup
    return nil, tokens if !rest[0] || rest[0][:type] != :left_bracket
    rest.shift #left bracket
    members = []
    while rest[0] && rest[0][:type] != :right_bracket
      item, rest = make_expression(rest)
      raise Exception, "Invalid array item" if !rhs
      members.push(item)
      rest.shift if rest[0] && rest[0][:type] == :comma
    end
    rest.shift # right bracket
    return { type: :array_literal, value: members }, rest
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
