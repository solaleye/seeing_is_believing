require 'seeing_is_believing'

describe SeeingIsBelieving::SyntaxAnalyzer do
  it 'knows if syntax is valid' do
    is_valid = lambda { |code| described_class.valid_ruby? code }
    is_valid['1+2'].should be_true
    is_valid['+'].should be_false

    # due to what are possibly bugs in Ripper
    # these don't raise any errors, so have to check them explicitly
    is_valid["'"].should be_false
    is_valid["/"].should be_false
  end

  it 'knows if the last line is a comment' do
    is_comment = lambda { |code| described_class.ends_in_comment? code }
    is_comment['# whatev'].should be_true
    is_comment['a # whatev'].should be_true
    is_comment["a \n b # whatev"].should be_true
    is_comment['a'].should be_false
    is_comment["a # whatev \n b"].should be_false
    is_comment[""].should be_false
  end

  # probably don't really need this many tests, but I'm unfamiliar with how thorough Ripper is
  # and already found areas where it doesn't behave correctly
  it 'knows if the code contains an unclosed string' do
    unclosed_string = lambda { |code| described_class.unclosed_string? code }
    [%(a),
     %("a"),
     %("a \n"),
     %("a \n a"),
     %(a \n" a"),
     %(a \n' a'),
     %('a' "b"),
     %('a"b'),
     %("a'b"),
     %("a\\""),
     %(%()),
     %(%<>),
     %(%[]),
     %(%{}),
     %(%Q()),
     %(%q()),
     %("\#{""}"),
     %("\#{''}"),
     %("\#{%(\#{%[\#{%[]}]})}"),
     %(%{}),
     %(%<>),
     %(%..),
    ].each do |string|
      unclosed_string[string].should be_false, "Expected #{string.inspect} to be closed"
    end

    [%(a "),
     %(a '),
     %("a \n),
     %(a \n 'a\n),
     %("a"\n"b),
     %("a" "b),
     %("a" "b'),
     %("a\\"),
     %('a\\'),
     %(%\(),
     %(%<),
     %(%[),
     %(%{),
     %(%Q[),
     %(%q[),
     %(%Q(\#{)),
     %("\#{),
     %("\#{'}"),
     %("\#{"}"),
     %("\#{%(\#{%[\#{%[}]})}"),
    ].each do |string|
      unclosed_string[string].should be_true, "Expected #{string.inspect} to be unclosed"
    end
  end

  it 'knows if the code contains an unclosed regexp' do
    unclosed_regexp = lambda { |code| described_class.unclosed_regexp? code }
    [%(a),
     %(/a/),
     %(/a \n/),
     %(/a \n a/),
     %(a \n/ a/),
     %(/a\\//),
     %(/\#{//}/),
     %(%r()),
     %(%r{}),
     %(%r<>),
     %(%r..),
    ].each do |code|
      unclosed_regexp[code].should be_false, "Expected #{code.inspect} to be closed"
    end

    [%(a + /),
     %(/a \n),
     %(a \n /a\n),
     %(/a/\n/b),
     %(/a\\/),
     %(%r\(),
     %(%r<),
     %(%r[),
     %(%r{),
     %(%r(\#{)),
     %(%r[\#{),
     %("\#{%r[}"),
    ].each do |code|
      unclosed_regexp[code].should be_true, "Expected #{code.inspect} to be unclosed"
    end
  end

  it "knows if the code contains a return (can't capture a void value)" do
    contains_return = -> code { described_class.contains_return? code }
    contains_return["return 1"].should be_true
    contains_return["return 1 if true"].should be_true
    contains_return["return 1 if false"].should be_true
    contains_return["o.return"].should be_false
    contains_return[":return"].should be_false
    contains_return["'return'"].should be_false
    contains_return["'return\nreturn\nreturn'"].should be_false
    contains_return["def a\nreturn 1\nend"].should be_false
    contains_return["-> {\nreturn 1\n}"].should be_false
    contains_return["Proc.new {\nreturn 1\n}"].should be_false
  end
end
