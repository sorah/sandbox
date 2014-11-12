speed = {}
lasts = {300 => nil, 60 => nil, 30 => nil, 5 => nil}
counters = Hash.new(0)

prev = Time.now
while _ = $stdin.gets.chomp
  time = Time.parse(_.match(/^\[(.+?)\]/)[1])

  lasts.each_key do |int|
    last = lasts[int]
    counters[int] += 1

    if prev <= time && int < (time - (last || Time.at(1)))
      speed[int] = counters[int]
      puts "#{time.strftime("%H:%M:%S")} #{speed.map{|i,c| "#{c}/#{i}sec" }.join(", ")}"
      lasts[int] = time
      counters[int] = 0
    end
  end
  prev = time
end
