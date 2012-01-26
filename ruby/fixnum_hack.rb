def t(n,e)
  puts n + ' -- ' + e.inspect
end

class Fixnum
  def self.method_missing(mn,*args)
    hit_single   = /^(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|fourty|fifty|sixty|seventy|eighty|ninety)$/
    single_integ = Proc.new do |n|
      case n
      when /^one/       then 1
      when /^two/       then 2
      when /^three/     then 3
      when /^four/      then 4
      when /^five/      then 5
      when /^six/       then 6
      when /^seven/     then 7
      when /^eight/     then 8
      when /^nine/      then 9
      when /^eleven/    then 11
      when /^twelve/    then 12
      when /^thirteen/  then 13
      when /^fourteen/  then 14
      when /^fifteen/   then 15
      when /^sixteen/   then 16
      when /^seventeen/ then 17
      when /^eighteen/  then 18
      when /^nineteen/  then 19
      when /^ten/       then 10
      when /^twenty/    then 20
      when /^thirty/    then 30
      when /^fourty/    then 40
      when /^fifty/     then 50
      when /^sixty/     then 60
      when /^seventy/   then 70
      when /^eighty/    then 80
      when /^ninety/    then 90
      end
    end

    case mn.to_s
    when hit_single then single_integ.call(mn.to_s)
    when /^(twenty|thirty|fourty|fifty|sixty|seventy|eighty|ninety)_(one|two|three|four|five|six|seven|eight|nine)/
      single_integ.call($1) + single_integ.call($2)
    else
      super
    end
  end
end


