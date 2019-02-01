# encoding: utf-8

require 'rspec'
require_relative '../src/main'

RSpec.describe EZPZ do

  before do
    $use_logger = false

    @lang = EZPZ.new
    @parser = @lang.parser
  end

  before(:each) do
    @lang.clear_cache
  end

  it 'assigns variables' do
    # Fixnum
    @parser.parse('@a << 5').eval
    expect(@lang.get_and_clear_vars).to include(a: 5)

    # Float
    expect { @parser.parse('@a << 5.0') }.to raise_error(RuntimeError)
    @parser.parse('@a << 5.1').eval
    expect(@lang.get_and_clear_vars).to include(a: 5.1)

    # Boolean
    @parser.parse('@a << True').eval
    expect(@lang.get_and_clear_vars).to include(a: true)

    @parser.parse('@a << False').eval
    expect(@lang.get_and_clear_vars).to include(a: false)

    # String
    @parser.parse('@a << "hello"').eval
    expect(@lang.get_and_clear_vars).to include(a: 'hello')

    @parser.parse('@a << "hello ∞"').eval
    expect(@lang.get_and_clear_vars).to include(a: 'hello ∞')
  end

  it 'assigns with arithmetic expression' do
    @parser.parse('@a << 5 + 5 + 10').eval
    expect(@lang.get_and_clear_vars).to include(a: 20)

    @parser.parse('@a << 10 + 10 - 5').eval
    expect(@lang.get_and_clear_vars).to include(a: 15)

    @parser.parse('@a << 10.5 + 0.15 - 5').eval
    expect(@lang.get_and_clear_vars).to include(a: 5.65)

    @parser.parse("@a << 5\n@b << @a + 2").eval
    expect(@lang.get_and_clear_vars).to include(b: 7)

    @parser.parse('@a << 10 * 10').eval
    expect(@lang.get_and_clear_vars).to include(a: 100)

    @parser.parse('@a << 11 %% 2').eval
    expect(@lang.get_and_clear_vars).to include(a: 1)

    @parser.parse('@a << 10 ^ 2').eval
    expect(@lang.get_and_clear_vars).to include(a: 100)
  end

  it 'assigns with comparison expression' do
    @parser.parse('@a << 5 < 10').eval
    expect(@lang.get_and_clear_vars).to include(a: true)

    @parser.parse('@a << 5 > 10').eval
    expect(@lang.get_and_clear_vars).to include(a: false)

    @parser.parse('@a << 5 <= 10').eval
    expect(@lang.get_and_clear_vars).to include(a: true)

    @parser.parse('@a << 10 <= 10').eval
    expect(@lang.get_and_clear_vars).to include(a: true)

    @parser.parse('@a << 5 >= 10').eval
    expect(@lang.get_and_clear_vars).to include(a: false)

    @parser.parse('@a << 10 >= 10').eval
    expect(@lang.get_and_clear_vars).to include(a: true)

    @parser.parse('@a << 5 = 10').eval
    expect(@lang.get_and_clear_vars).to include(a: false)

    @parser.parse('@a << 10 = 10').eval
    expect(@lang.get_and_clear_vars).to include(a: true)

    @parser.parse('@a << 5 =/= 10').eval
    expect(@lang.get_and_clear_vars).to include(a: true)

    @parser.parse('@a << 10 =/= 10').eval
    expect(@lang.get_and_clear_vars).to include(a: false)
  end

  it 'works with arithmetic expressions and parentheses' do
    @parser.parse('@a << 5 - (10 + 5)').eval
    expect(@lang.get_and_clear_vars).to include(a: -10)
  end

  it 'works with comparison expressions and parentheses' do
    @parser.parse('@a << 5 < (10 + 5)').eval
    expect(@lang.get_and_clear_vars).to include(a: true)
  end

  it 'assigns with arithmetic/comparison expression' do
    @parser.parse('@a << 5 + 10 < 20').eval
    expect(@lang.get_and_clear_vars).to include(a: true)

    @parser.parse('@a << 10 < 20 + 5').eval
    expect(@lang.get_and_clear_vars).to include(a: true)

    @parser.parse('@a << 5.1 + 10 < 20 + 5').eval
    expect(@lang.get_and_clear_vars).to include(a: true)
  end

  it 'handles math operator priority' do
    @parser.parse('@a << 3 * 4 + 2').eval
    expect(@lang.get_and_clear_vars).to include(a: 14)
  end

  it 'works with multiple statements' do
    @parser.parse("@a << 10\n@b << 20").eval
    expect(@lang.get_and_clear_vars).to include(a: 10, b: 20)

    @parser.parse("@a << 10\n@b << 20 < 10").eval
    expect(@lang.get_and_clear_vars).to include(a: 10, b: false)

    @parser.parse("@a << 10\n@a << @a < 10").eval
    expect(@lang.get_and_clear_vars).to include(a: false)
  end

  it 'handles variable calls' do
    @parser.parse("@a << 10\n@b << @a").eval
    expect(@lang.get_and_clear_vars).to include(a: 10, b: 10)
  end

  it 'can overwrite variables' do
    @parser.parse("@a << 10\n@a << 20 < 10").eval
    expect(@lang.get_and_clear_vars).to include(a: false)
  end

  it 'throws error when variable not found' do
    expect { @parser.parse('@a').eval }.to raise_error(NameError)
  end

  it 'has support for if blocks' do
    # IF
    @parser.parse(%q{
    @a << 6 + 4
    @b << 0

    (4.2 < 5.8)?
        @b << 4!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 10, b: 4)
  end

  it 'has support for if else blocks' do
    # IF
    @parser.parse(%q{
    @a << 6 - 4
    @b << 0

    (4 < 5.27)?
        @b << 4!
    @c << 4!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 2, b: 4)

    # IF ELSE
    @parser.parse(%q{
    @a << 6 - 4
    @c << 0

    (4 > 5.27)?
        @b << 4!
    @c << 5!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 2, c: 5)
  end

  it 'has support for if elseif blocks' do
    # IF
    @parser.parse(%q{
    @a << 6 + 4.5
    @b << 0

    (4 < 7)?
        @b << 4!
    (10.5 <= 20)?!
        @c << 5!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 10.5, b: 4)

    # IF ELSEIF
    @parser.parse(%q{
    @a << 6.5 + 4
    @c << 0

    (4 > 5)?
        @b << 4!
    (10.5 <= 20)?!
        @c << 5!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 10.5, c: 5)
  end

  it 'has support for if elseif (1x) else blocks' do
    # IF
    @parser.parse(%q{
    @a << 10.4 - 5
    @b << 0

    (1 = 1)?
        @b << 5!
    (True)?!
        @c << 7!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 5.4, b: 5)

    # IF ELSEIF
    @parser.parse(%q{
    @a << 10.4 - 5
    @c << 0

    (1 =/= 1)?
        @b << 5!
    (10.5 >= 10)?!
        @c << 7!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 5.4, c: 7)

    # IF ELSEIF ELSE
    @parser.parse(%q{
    @a << 10.4 - 5
    @d << 0

    (1 =/= 1)?
        @d << 5!
    (10 >= 10.5)?!
        @d << 7!
    @d << 8!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 5.4, d: 8)
  end

  it 'has support for if elseif (2x) else blocks' do
    # IF
    @parser.parse(%q{
    @a << 10.4 - 5
    @b << 0

    (1 = 1)?
        @b << 5!
    (True)?!
        @c << 7!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 5.4, b: 5)

    # IF ELSEIF
    @parser.parse(%q{
    @a << 10.4 - 5
    @c << 0

    (1 =/= 1)?
        @b << 5!
    (10.5 >= 10)?!
        @c << 7!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 5.4, c: 7)

    # IF ELSEIF ELSEIF
    @parser.parse(%q{
    @a << 10.4 - 5
    @d << 0

    (1 =/= 1)?
        @b << 5!
    (0.5 >= 1.52)?!
        @c << 7!
    (2.5 > 1.52)?!
        @d << 3!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(d: 3)

    # IF ELSEIF ELSEIF ELSE
    @parser.parse(%q{
    @a << 10.4 - 5
    @e << 0

    (1 =/= 1)?
        @b << 5!
    (0.5 >= 1.52)?!
        @c << 7!
    (2.5 < 1.52)?!
        @d << 3!
    @e << 8.2!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 5.4, e: 8.2)
  end

  it 'has support for nested if blocks' do
    # IF (IF)
    @parser.parse(%q{
    @a << 6.5 + 1
    @b << 0
    @c << 0

    (4 < 5)?
        @b << 4
        (1.5 > 1)?
            @c << 1!!!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 7.5, b: 4, c: 1)

    # IF (IF ELSE)
    @parser.parse(%q{
    @a << 6.5 + 1
    @b << 0
    @d << 0

    (4 < 5)?
        @b << 4
        (1.5 < 1)?
            @c << 1!
        @d << 22!!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 7.5, b: 4, d: 22)

    # IF (IF ELSE) ELSE
    @parser.parse(%q{
    @a << 6.5 + 1
    @e << 0

    (5 < 5)?
        @b << 4
        (1.5 < 1)?
            @c << 1!
        @d << 22!!
    @e << 21!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 7.5, e: 21)
  end

  it 'has support for while loops' do
    @parser.parse(%q{
    @a << 1
    (@a < 10)∞
        @a << @a + 1!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 10)

    # Create more.
  end

  it 'has support for functions' do
    @parser.parse(%q{
    (@arg)$kalle
        @arg + 1!
    @result << (1)$kalle
    }).eval
    expect(@lang.get_and_clear_vars).to include(result: 2)
  end

  it 'has support for functions 2 parameters' do
    @parser.parse(%q{
    @a << 1
    (@a, @b)$summa
        @a + @b!
    @result << (@a, 2)$summa
    }).eval
    expect(@lang.get_and_clear_vars).to include(result: 3)
  end

  it 'has support for nested functions' do
    @parser.parse(%q{
    (@a, @b)$sum
        (@a)$square
            @a ^ 2!
        (@a)$square + (@b)$square!

    @c << (2, 2)$sum
    }).eval
    expect(@lang.get_and_clear_vars).to include(c: 8)
  end

  it 'has scoping' do
    expect do
      @parser.parse(%q{
      @a << 1

      (True)?
          @b << @a
          (True)?
              @c << @a!!
          @d << @c!!
      }).eval
    end.to raise_error(NameError)

    @parser.parse(%q{
    @a << 1
    @b << 0
    @c << 0

    (True)?
        @b << @a
        (True)?
            @c << @a!!!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 1, b: 1, c: 1)
  end

  it 'works with bitwise operators (&)' do
    # 00
    @parser.parse(%q{
    @a << 0
    @b << False
    @c << False

    (@b & @c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 0)

    # 01
    @parser.parse(%q{
    @a << 0
    @b << False
    @c << True

    (@b & @c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 0)

    # 10
    @parser.parse(%q{
    @a << 0
    @b << True
    @c << False

    (@b & @c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 0)

    # 11
    @parser.parse(%q{
    @a << 0
    @b << True
    @c << True

    (@b & @c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 1)
  end

  it 'works with bitwise operators (|)' do
    # 00
    @parser.parse(%q{
    @a << 0
    @b << False
    @c << False

    (@b | @c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 0)

    # 01
    @parser.parse(%q{
    @a << 0
    @b << False
    @c << True

    (@b | @c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 1)

    # 10
    @parser.parse(%q{
    @a << 0
    @b << True
    @c << False

    (@b | @c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 1)

    # 11
    @parser.parse(%q{
    @a << 0
    @b << True
    @c << True

    (@b | @c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 1)
  end

  it 'works with the "not" operator' do
    @parser.parse(%q{
    @a << 0
    @b << False

    (#@b)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 1)

    @parser.parse(%q{
    @a << 0
    @b << True

    (#@b)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 0)
  end

  it 'works with the "not" operator and bitwise (&)' do
    # In combo with bitwise (&)
    @parser.parse(%q{
    @a << 0
    @b << True
    @c << True

    (#@b & @c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 0)

    @parser.parse(%q{
    @a << 0
    @b << True
    @c << True

    (@b & #@c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 0)

    @parser.parse(%q{
    @a << 0
    @b << True
    @c << True

    (#@b & #@c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 0)


    @parser.parse(%q{
    @a << 0
    @b << False
    @c << False

    (#@b & @c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 0)

    @parser.parse(%q{
    @a << 0
    @b << False
    @c << False

    (@b & #@c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 0)

    @parser.parse(%q{
    @a << 0
    @b << False
    @c << False

    (#@b & #@c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 1)
  end

  it 'works with the "not" operator and bitwise (|)' do
    # In combo with bitwise (|)
    @parser.parse(%q{
    @a << 0
    @b << True
    @c << True

    (#@b | @c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 1)

    @parser.parse(%q{
    @a << 0
    @b << True
    @c << True

    (@b | #@c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 1)

    @parser.parse(%q{
    @a << 0
    @b << True
    @c << True

    (#@b | #@c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 0)


    @parser.parse(%q{
    @a << 0
    @b << False
    @c << False

    (#@b | @c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 1)

    @parser.parse(%q{
    @a << 0
    @b << False
    @c << False

    (@b | #@c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 1)

    @parser.parse(%q{
    @a << 0
    @b << False
    @c << False

    (#@b | #@c)?
        @a << 1!!
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 1)
  end

  it 'has support for function calls in parameters' do
    @parser.parse(%q{
    @a << 0

    (@a)$func_a
        @a + 1!

    (@a)$func_b
        @a + 2!

    @a << ((1)$func_a)$func_b
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 4)
  end

  it 'can print' do
    expect do
      @parser.parse(%q{
      @a << 0
      @b << 1

      (@a, @b)$print
      }).eval
    end.to output("0.0\n1.0\n").to_stdout
  end

  it 'concatenates strings' do
    @parser.parse(%q{
    (@a, @b)$concat
        @a + @b!
    @a << ("Hello ", "m8")$concat
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 'Hello m8')
  end

  it 'has support for a lot of things' do
    @parser.parse(%q{
    (@num)$is_prime
        @i << 2
        @prime << True
        (@i < @num)∞
            (@num %% @i = 0)?
                @prime << False!!
        @i << @i+1!
        @prime!
    @a << (6)$is_prime
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: false)
  end

  it 'works recursive factorial' do
    @parser.parse(%q{
    (@a)$n_fact
        @result << 0
        (@a <= 1)?
            @result << 1!
        @result << @a * (@a - 1)$n_fact!
        @result!
    @a << (5)$n_fact
    }).eval
    expect(@lang.get_and_clear_vars).to include(a: 120)
  end

end
