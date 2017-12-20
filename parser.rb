require "awesome_print"

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
    if tokens[0][:type] == :left_paren
      tokens.shift
      expr, rest = make_expression(tokens.dup)
      raise Exception, "Invalid expression after (" if !expr
      raise Exception, "`(` without `)`" if rest[0][:type] != :right_paren
      rest.shift
      return { action: :grouping, expression: expr }, rest
    end
    num, rest = make_number(tokens.dup)
    return num, rest if num
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

  def self.make_reference(tokens)
    if tokens[0] && tokens[0][:type] == :identifier
      ident = tokens[0][:value]
      tokens.shift
      if tokens[0] && tokens[0][:type] == :left_bracket
        tokens.shift
        ind, rest = make_expression(tokens.dup)
        raise Exception, "Invalid array index" if !ind
        if !rest[0] || rest[0][:type] != :right_bracket
          raise Exception, "Left bracket without right bracket"
        end
        rest.shift
        return {action: :reference, array: ident, index: ind}, rest
      elsif tokens[0] && tokens[0][:type] == :left_paren
        tokens.shift
        rest = tokens.dup
        params = []
        while rest[0] && rest[0][:type] != :right_paren do
          rest_orig = rest.dup
          expr, rest = make_expression(rest.dup)
          raise Exception, "Invalid parameter" if !expr
          if rest[0] && (rest[0][:type] != :comma && rest[0][:type] != :right_paren)
            raise Exception, "Invalid parameters to function call"
          end
          params.push(expr)
          rest.shift if rest[0] && rest[0][:type] == :comma
        end
        rest.shift if rest[0] && rest[0][:type] == :right_paren
        return {action: :func_call, function: ident, params: params}, rest
      else
        return {action: :reference, value: ident}, tokens
      end
    else
      return nil, tokens
    end
  end

end
