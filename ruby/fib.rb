class Fib
  @@ary = []

  def self.[](i)
    return @@ary[i] if @@ary[i]
    case i
    when 0
      @@ary[i] = 0
    when 1
      @@ary[i] = 1
    else
      @@ary[i] = self[i-1]+self[i-2]
    end
  end

  def self.method_missing(name,*args)
    @@ary.__send__(name,*args)
  end

  def self.inspect
    @@ary.inspect
  end
end

if __FILE__ == $0
  p Fib
  10.times do |i|
    p Fib[i]
  end
  p Fib
  Fib[100]
  p Fib
end
