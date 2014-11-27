path = File.expand_path('~/Music/djay/NowPlaying.txt')

prev = nil
pret = nil
t = nil
loop do
  now = File.read(path).each_line.map { |_| _.chomp.split(/: /,2) }.to_h
  if now != prev
    text = "#kosendj Now Playing: #{now['Title']} (#{now['Artist']})"
    if text.size > 135
      text = "#kosendj Now Playing: #{now['Title']}"
    end
    prev = now
    pret = t
    t = Time.now
    puts "#{t.to_s}: #{text} (#{t-(pret || Time.now)})"
  end
  sleep 1
end
