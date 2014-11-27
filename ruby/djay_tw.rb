require 'twitter'
prefix = ARGV[0] || ''
prefix << ' ' unless prefix.empty?
tw = Twitter::REST::Client.new(
  consumer_key: ENV['TWITTER_CONSUMER_KEY'],
  consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
  access_token: ENV['TWITTER_ACCESS_TOKEN'],
  access_token_secret: ENV['TWITTER_ACCESS_TOKEN_SECRET'],
)
path = File.expand_path('~/Music/djay/NowPlaying.txt')

prev = nil
pret = nil
t = nil
loop do
  now = File.read(path).each_line.map { |_| _.chomp.split(/: /,2) }.to_h
  if now != prev
    text = "#{prefix}Now Playing: #{now['Title']} (#{now['Artist']})"
    if text.size > 135
      text = "#{prefix}Now Playing: #{now['Title']}"
    end
    tw.update(text) if prev
    prev = now
    pret = t
    t = Time.now
    puts "#{t.to_s}: #{text} (#{t-(pret || Time.now)})"
  end
  sleep 1
end
