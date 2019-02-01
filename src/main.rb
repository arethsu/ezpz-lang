# encoding: utf-8

require_relative 'rdparse'
require_relative 'node'

class EZPZ

  attr_reader :parser, :variables

  def initialize
    @variables = $variables

    @parser = Parser.new('EZPZ') do

      token(/\s+/)

      token(/-?((0|[1-9]\d*)\.\d*[1-9])/) { |numeral| numeral.to_f.to_s } # Floats (pos and neg)
      token(/-?(0|[1-9]\d*)/) { |numeral| numeral.to_s } # Integers (pos and neg)
      token(/[a-zA-ZåäöÅÄÖ0-9_]+/) { |words| words } # Word characters
      token(/".*?"/) { |string| string } # Strings

      token(/(&|\|)/) { |character| character }
      token(/<</) { |character| character } # Assignment operator
      token(/#/) { |character| character }

      # These mess up if you put them separately (\+|-).
      token(/(\+|-)/) { |character| character }

      token(/(\*|\/|%%|\^)/) { |character| character }
      token(/@/) { |character| character }
      token(/(<=|>=)/) { |character| character }
      token(/(=\/=|=)/) { |character| character }
      token(/(\)\?!|\)\?|\)∞|\)\$)/) { |character| character }
      token(/!/) { |character| character }

      # These mess up if you put them separately `<|>`.
      token(/(<|>)/) { |character| character }

      token(/\(|\)|,/) { |character| character }

      token(/(True|False)/) { |boolean| boolean }

      start :program do
        match(:statements) { |statements| Program.new(statements) }
      end

      rule :statements do

        match(:statement, :statements) { |statement, statements| ([statement] + statements).flatten }
        match(:statement) { |statement| [statement] }

      end

      rule :statement do

        match(:function_dec)
        match(:variable_dec)
        match(:condition)
        match(:loop)
        match(:expression)
        match(:function_call)
        match(:variable_call)
      end

      rule :variable_dec do

        match('@', :allowed_chr, '<<', :expression) do |_, var_name, _, expression|
          VariableDec.new(var_name, expression)
        end

      end

      rule :variable_call do

        match('@', :allowed_chr) do |_, var_name|
          VariableCall.new(var_name)
        end

      end

      rule :function_dec do

        match('(', :arguments, ')$', :allowed_chr, :statements, '!') do |_, arguments, _, func_name, statements|
          FunctionDec.new(arguments, func_name, statements)
        end

      end

      rule :arguments do

        match('@', :allowed_chr, ',', :arguments) do |_, argument, _, arguments|
          ([argument] + arguments).flatten
        end

        match('@', :allowed_chr) do |_, argument|
          [argument]
        end

      end

      rule :function_call do

        match('(', :parameters, ')$', :allowed_chr) do |_, parameters, _, func_name|
          FunctionCall.new(parameters, func_name)
        end

      end

      rule :parameters do

        match(:expression, ',', :parameters) do |parameter, _, parameters|
          ([parameter] + parameters).flatten
        end

        match(:expression) do |parameter|
          [parameter]
        end

      end

      rule :condition do

        match(:start_if, :else_ifs, :statements, '!') do |start_if, else_ifs, statements|
          Condition.new(start_if[:expression], start_if[:statements], else_ifs, statements)
        end

        match(:start_if, :else_ifs, '!') do |start_if, else_ifs|
          Condition.new(start_if[:expression], start_if[:statements], else_ifs)
        end

        match(:start_if, :statements, '!') do |start_if, statements|
          Condition.new(start_if[:expression], start_if[:statements], [], statements)
        end

        match(:start_if, '!') do |start_if|
          Condition.new(start_if[:expression], start_if[:statements])
        end

      end

      rule :start_if do

        match('(', :expression, ')?', :statements, '!') do |_, expression, _, statements|
          { expression: expression, statements: statements }
        end

      end

      rule :else_ifs do

        match('(', :expression, ')?!', :statements, '!', :else_ifs) do |_, expression, _, statements, _, else_ifs|
          else_ifs.unshift(Condition.new(expression, statements))
        end

        match('(', :expression, ')?!', :statements, '!') do |_, expression, _, statements|
          [Condition.new(expression, statements)]
        end

      end

      rule :loop do

        match('(', :expression, ')∞', :statements, '!') do |_, expression, _,  statements|
          Loop.new(expression, statements)
        end

      end

      rule :expression do

        match(:expression, /&|\|/, :bitwise) do  |l_expression, operator, r_expression|
          Expression.new(l_expression, operator, r_expression)
        end

        match(:bitwise)
      end

      rule :bitwise do

        match(:bitwise, /=\/=|<=|>=|=|<|>/, :expra) do  |l_expression, operator, r_expression|
          Expression.new(l_expression, operator, r_expression)
        end

        match(:expra)

      end

      rule :expra do

        match(:expra, /\+|-/, :term) do |l_expression, operator, r_expression|
          Expression.new(l_expression, operator, r_expression)
        end

        match(:term)

      end

      rule :term do

        match(:term, /\*|\/|%%/, :expo) do |l_expression, operator, r_expression|
          Expression.new(l_expression, operator, r_expression)
        end

        match(:expo)

      end

      rule :expo do

        match(/#/, :atom) do |operator, expression|
          Not.new(expression)
        end

        match(:expo, /\^/, :atom) do |l_expression, operator, r_expression|
          Expression.new(l_expression, operator, r_expression)
        end

        match(:atom)

      end

      rule :atom do

        match(:operand)

        match('(', :expression, ')') do |_, expression|
          expression
        end

      end

      rule :operand do

        match(:function_call)
        match(:variable_call)
        match(/".*?"/) { |string| string[1..(string.length - 2)] } # Strings (escaping?)
        match(/(0|[1-9]\d*)\.\d*[1-9]/) { |f_num| f_num.to_f } # Float values
        match(/0|[1-9]\d*/) { |i_num| i_num.to_f } # Integer values
        match(/True|False/) { |boolean| boolean == 'True' } # Boolean values

      end

      rule :allowed_chr do
        match(/[a-zA-ZåäöÅÄÖ0-9]+/) { |match| match }
      end

    end
  end

  def clear_cache
    $variables = [{}]
    $functions = {}
  end

  def get_variables
    $variables
  end

  def get_and_clear_vars
    variables = $variables
    clear_cache
    variables.reduce({}, :merge)
  end

end
