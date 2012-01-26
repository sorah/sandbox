# This is a public domain

class Matcher
  DEFAULT_KEY = :foo

  def initialize(obj, default = DEFAULT_KEY)
    @default = default
    @obj = obj
  end

  def match(*args)
    regexps = []
    la, lb = ->(conds, method = :any?) do
      conds.__send__(method) do |cond|
        case cond
        when Array
          la[cond]
        when Hash
          lb[cond]
        when Regexp
          @obj[@default].kind_of?(String) && (regexps << @obj[@default].match(cond))[-1]
        else
          @obj[@default] == cond
        end
      end
    end, ->(hash, method = :any?) do
      hash.__send__(method) do |key,value|
        case key
        when :any
          case value
          when Array
            return la[value]
          when Hash
            return lb[value]
          else
            raise TypeError
          end
        when :all
          case value
          when Array
            return la[value, :all?]
          when Hash
            return lb[value, :all?]
          else
            raise TypeError
          end
        else
          value = [value] unless value.kind_of?(Array)

          # TODO: hierarchical hash
          return value.any? do |cond|
            cond.kind_of?(Regexp) ? (regexps << @obj[key].match(cond)).last \
                                  : @obj[key] == cond
          end
        end
      end
    end
    la[args] && regexps.compact
  end

  def match?(*args)
    self.match(args) ? true : false
  end
end

if __FILE__ == $0
  # Usage
  matcher = Matcher.new(foo: "bar", bar: "foo")

  p matcher.match?("bar") #=> true
  p matcher.match?("baa") #=> false
  p matcher.match?("baa", "bar") #=>true
  p matcher.match?("baa", /b/) #=>true
  p matcher.match?(/ba/)  #=> true
  p matcher.match?(/fo/)  #=> false
  p matcher.match?(/fo/, /ba/)  #=> true
  p matcher.match?(foo: /b/)  #=> true
  p matcher.match?(foo: /f/)  #=> false
  p matcher.match?(bar: "foo")  #=> true
  p matcher.match?(bar: "bar")  #=> false
  p matcher.match?(foo: "bar", bar: "bar")  #=> true
  p matcher.match?(foo: /b/, bar: "bar")  #=> true
  p matcher.match?(foo: /b/, bar: /ba/)  #=> true
  p matcher.match?(foo: /f/, bar: /ba/)  #=> false
  p matcher.match?(foo: "b", bar: /ba/)  #=> false
  p matcher.match?(foo: ["foo", "bar"])  #=> true
  p matcher.match?(foo: ["foo", /b/])  #=> true
  p matcher.match?(all: [{foo: "bar"}, {bar: "foo"}]) #=> true
  p matcher.match?(all: {foo: "bar", bar: "foo"}) #=> true
  p matcher.match?(all: [{foo: "foo"}, {bar: "foo"}]) #=> false
  p matcher.match?(all: {foo: "foo", bar: "foo"}) #=> false
  p matcher.match?(all: {foo: "bar", any: {foo: "foo", bar: "foo"}}) #=> true
  p matcher.match?(any: [{foo: "bar"}, {bar: "foo"}]) #=> true
  p matcher.match?(any: {foo: "bar", bar: "foo"}) #=> true
  p matcher.match?(any: [{foo: "foo"}, {bar: "foo"}]) #=> true
  p matcher.match?(any: {foo: "foo", bar: "foo"}) #=> false
  p matcher.match?(any: {foo: "bar", any: {foo: "foo", bar: "foo"}}) #=> true
end
