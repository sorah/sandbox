#-*- coding:utf-8 -*-
class Lamb
  LAMBDAS = ["λ", "\\"]

  def self.run(code)
    self.new.run(code)
  end

  def initialize
  end

  def run(code)
    parse(code).reduce
  end

  def parse(code)
    arrayed = (f = ->(c) do
      r = []
      while _ = c.shift
        case _
        when '('
          r << f[c]
        when ')'
          return r
        when ' ', "\n"
        else
          r << _
        end
      end
      r
    end)[code.chars.to_a]

    f, _f = ->(_) do
      case _
      when Array
        _f[_]
      else
        _.to_sym
      end
    end,    ->(_) do
      if LAMBDAS.include?(_[0])
        _=_.dup
        _.shift
        args = []
        arg = nil
        args << arg until (arg = _.shift) == "."
        Da.new(args,_.map(&f))
      else
        _.map(&f)
      end
    end

    result = (_=_f[arrayed]).kind_of?(Array) ? _:[_]
    class << result; include TermArray; end
    result
  end

  class Da
    attr_reader :arguments, :to

    def initialize(arguments, to)
      @arguments = arguments.map(&:to_sym)
      @to = to
    end

    def apply(given)
      arg = (args = @arguments.dup).shift

      replacer = ->(_) do
        if _.kind_of?(Array)
          class << _; include TermArray; end
          _=_.reduce
          _.kind_of?(Array) ? _.map(&replacer) : (_=_.dup.to.map!(&replacer) && _)
        elsif _.kind_of?(Da) && !_.arguments.include?(arg)
          _.dup.to.map!(&replacer)
          _
        elsif _ == arg
          given
        else
          _
        end
      end
      replaced = @to.dup.map(&replacer)
      class << replaced; include TermArray; end

      if args.empty?
        replaced
      else
        Da.new(args, replaced)
      end
    end

    def inspect; "#(->#{@arguments.join}.#{@to})"; end
    def to_s; "(λ#{@arguments.join}.#{@to.join(" ")})"; end
  end

  module TermArray
    def reduce
      terms = self.dup

      applier, _applier = ->(t,i=0) do
        while t.flatten[0].kind_of?(Da) && t.size > 1
          t.unshift *_applier[t.shift,t.shift,i]
        end
        t
      end, ->(_,__,i=0) do
        if _.kind_of?(Array)
          r = applier[_,i+1]
          if r[0].kind_of?(Da)
            r = r[0].apply(__)
          end
        else
          r = _.kind_of?(Da) ? _.apply(__) : [_,__]
        end

        if r.kind_of?(Array) && r.size == 1
          r[0]
        else
          r
        end
      end

      _ = applier[terms]
      class << _; include TermArray; end

      _.size == 1 ? _[0] : _
    end

    def to_s
      self.map(&(f=->(_) do
        case _
        when Array
          "(#{_.map(&f).join(" ")})"
        else
          _.to_s
        end
      end)).join(" ")
    end
  end
end

if ARGV[0]
  require 'readline'
  while l = Readline.readline("> ", true)
    puts Lamb.run(l).to_s
  end
else
  #p Lamb.run("(λxyz.x z (y z)) a (λxy.x) c")
  #p Lamb.run("(λx.(λy.x)) a b")
  puts Lamb.run("(λx.(λy.x y))(λxy.y) a").to_s
end
