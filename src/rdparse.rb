# encoding: utf-8

require 'logger'
require 'pp'

$use_logger = false

class Rule

  Match = Struct.new(:pattern, :block)

  def initialize(name, parser)
    @logger = parser.logger
    @name, @parser = name, parser
    @matches, @lrmatches = [], []
  end

  def match(*pattern, &block)
    match = Match.new(pattern, block)

    if pattern[0] == @name
      pattern.shift
      @lrmatches << match
    else
      @matches << match
    end
  end

  def parse
    match_result = try_matches(@matches)
    return nil if match_result.nil?

    loop do
      result = try_matches(@lrmatches, match_result)
      return match_result if result.nil?
      match_result = result
    end
  end

  private

  def try_matches(matches, pre_result = nil)
    match_result = nil

    start = @parser.pos
    matches.each do |match|

      result = (pre_result.nil? ? [] : [pre_result])

      match.pattern.each_with_index do |token, index|

        if @parser.rules[token]

          result << @parser.rules[token].parse
          if result.last.nil?
            result = nil
            break
          end

          @logger.debug("Matched '#{@name} = #{match.pattern[index..-1].inspect}'") if $use_logger

        else

          nt = @parser.expect(token)

          if nt
            result << nt

            @lrmatches.include?(match.pattern) ? pattern = [@name] + match.pattern : pattern = match.pattern

            @logger.debug("Matched token '#{nt}' as part of rule '#{@name} <= #{pattern.inspect}'") if $use_logger
          else
            result = nil
            break
          end
        end
      end

      if result

        if match.block
          match_result = match.block.call(*result)
        else
          match_result = result[0]
        end

        if $use_logger
          unless match_result.nil?
            @logger.debug("'#{@parser.string[start..(@parser.pos - 1)]}' matched '#{@name}' and generated:")
            pp match_result
          end
        end

        break
      end

      @parser.pos = start
    end

    match_result
  end
end

class Parser

  attr_accessor :pos
  attr_reader :rules, :string, :logger

  def initialize(language_name, &block)
    @logger = Logger.new(STDOUT)
    @lex_tokens = []
    @rules = {}
    @start = nil
    @language_name = language_name

    instance_eval(&block)
  end

  def tokenize(string)
    @tokens = []
    @string = string.clone

    until string.empty?
      raise "unable to lex '#{string}'" unless @lex_tokens.any? do |token|
        pp string if $use_logger

        match = token.pattern.match(string)

        if match
          @logger.debug("Token #{match[0]} consumed") if $use_logger
          @tokens << token.block.call(match.to_s) if token.block
          string = match.post_match
          puts @tokens.inspect if $use_logger
          true
        else
          false
        end
      end
    end
  end

  def parse(input)

    if input.instance_of?(File)
      input = input.read
    end

    tokenize(input)

    @pos = 0
    @max_pos = 0
    @expected = []
    result = @start.parse

    (raise "expected '#{@expected.join(', ')}', found '#{@tokens[@max_pos]}'" unless @pos == @tokens.size) if $use_logger

    result
  end

  def next_token
    @pos += 1
    @tokens[@pos - 1]
  end

  def expect(tok)
    return tok if tok == :empty
    t = next_token

    if @pos - 1 > @max_pos
      @max_pos = @pos - 1
      @expected = []
    end

    return t if tok === t
    @expected << tok if @max_pos == @pos - 1 && !@expected.include?(tok)

    nil
  end

  private

  LexToken = Struct.new(:pattern, :block)

  def token(pattern, &block)
    @lex_tokens << LexToken.new(Regexp.new('\\A' + pattern.source), block)
  end

  def start(name, &block)
    rule(name, &block)
    @start = @rules[name]
  end

  def rule(name, &block)
    @current_rule = Rule.new(name, self)
    @rules[name] = @current_rule
    instance_eval(&block)
    @current_rule = nil
  end

  def match(*pattern, &block)
    @current_rule.send(:match, *pattern, &block)
  end

end
