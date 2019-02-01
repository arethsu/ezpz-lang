# encoding: utf-8

$variables = [{}]
$functions = {}


class Program

  attr_reader :statements

  def initialize(statements)
    @statements = statements
  end

  def eval
    @statements.each(&:eval)
  end

end

class VariableDec

  attr_reader :name, :expression
  attr_accessor :scope

  def initialize(name, expression)
    @name, @expression = name.to_sym, expression
  end

  def eval
    found = false

    (0..($variables.length - 1)).reverse_each do |index|

      unless $variables[index][@name].nil?
        $variables[index][@name] = @expression.eval
        found = true
        break
      end

    end

    if found == false
      $variables.last[@name] = @expression.eval
    end
  end
end

class VariableCall

  attr_reader :name

  def initialize(name)
    @name = name.to_sym
  end

  def eval
    callback = nil

    (0..($variables.length - 1)).reverse_each do |index|

      unless $variables[index][@name].nil?
        callback = $variables[index][@name]
        break
      end

    end

    raise NameError, "variable #{@name.inspect} not declared" if callback.nil?
    callback
  end

end

class FunctionDec

  attr_reader :arguments, :statements

  def initialize(arguments, name, statements)
    @arguments, @name, @statements = arguments, name, statements

  end

  def eval
    $functions[@name.to_sym] = Function.new(@arguments, @statements)
  end

end

class FunctionCall

  attr_reader :parameters, :name

  def initialize(parameters, name)
    @parameters, @name = parameters, name
  end

  def eval
    if name == 'print'
      parameters.map(&:eval).each(&method(:print))
    else
      callback = $functions[@name.to_sym]
      raise NameError, "function #{@name.inspect} not defined" if callback.nil?
      callback.eval(parameters.map(&:eval))
    end
  end

end

class Function

  attr_reader :arguments, :statements

  def initialize(arguments, statements)
    @arguments, @statements = arguments, statements
  end

  def eval(parameters)
    if @arguments.length != parameters.length
      raise ArgumentError, "wrong number of arguments (#{parameters.length} for #{@arguments.length})"
    end

    $variables << Hash[@arguments.map(&:to_sym).zip(parameters)]

    result = @statements.each do |statement|
      statement.eval
    end

    result = result.last.eval

    $variables.pop

    result
  end

end

class Fixnum

  def eval
    self
  end

end

class Float

  def eval
    self
  end

end

class String

  def eval
    self
  end

end

class TrueClass

  def eval
    self
  end

end

class FalseClass

  def eval
    self
  end

end


class Expression

  attr_reader :l_expression, :operator, :r_expression

  def initialize(l_expression, operator, r_expression)
    @l_expression, @r_expression = l_expression, r_expression
    #operators = {'=/=' => '!=', '=' => '==', '^' => '**', '%%' => '%'}
    #@operator = operators.key?(operator) ? operator[operator] : operator

    case operator
      when '=/='
        @operator = '!='
      when '='
        @operator = '=='
      when '^'
        @operator = '**'
      when '%%'
        @operator = '%'
      else
        @operator = operator
    end
  end

  def eval
    @l_expression.eval.send(@operator.to_sym, @r_expression.eval)
  end
end

class Not

  def initialize(expression)
    @expression = expression
  end

  def eval
    !@expression.eval
  end

end

class Condition

  attr_reader :statements, :else_ifs, :else_statements

  def initialize(expression, statements, else_ifs = [], else_statements = [])
    @expression = expression
    @statements = statements
    @else_ifs = else_ifs
    @else_statements = else_statements # `Statements` node
  end

  def eval
    $variables << {}

    if @expression.eval
      @statements.each do |statement|
        statement.eval
      end

      $variables.pop
      true
    else
      else_if_ran = false

      @else_ifs.each do |else_if|
        if else_if.eval
          else_if_ran = true
          break
        end
      end

      if else_if_ran == false
        @else_statements.each do |statement|
          statement.eval
        end
      end

      $variables.pop
      false
    end

  end

end

class Loop

  attr_reader :expression, :statements

  def initialize(expression, statements)
    @expression, @statements = expression, statements
  end

  def eval
    $variables << {}

    while @expression.eval
      @statements.each(&:eval)
    end

    $variables.pop
  end

end
