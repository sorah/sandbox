require 'fluent-logger'
require 'open-uri'
require 'nokogiri'

user = ENV['LF_USER']
marker = ENV['LF_MARKER'] || File.expand_path('~/.lastfm_fluentd.mark')
last = if File.exist?(marker)
         File.read(marker).chomp
       else
         nil
       end

tracks = Nokogiri::XML(open("http://ws.audioscrobbler.com/1.0/user/#{user}/recenttracks.xml", 'r', &:read))
latest = tracks.search('track').first

name = latest.at('name').inner_text
artist = latest.at('artist').inner_text
album = latest.at('album').inner_text

latest_mark = case
              when latest.at('url') && !latest.at('url').inner_text.empty?
                latest.at('url').inner_text
              when latest.at('date') && latest.at('date')['uts']
                latest.at('date')['uts']
              else
                [name, artist, album].join("\t")
              end

p lastrun: last, latest: latest_mark
exit if latest_mark.to_s == last

logger = Fluent::Logger::FluentLogger.new(ENV['LF_TAG_PREFIX'], host: ENV['FLUENTD_HOST'] || 'localhost', port: (ENV['FLUENTD_PORT'] || 24224).to_i)
message = "♫▶︎ #{name} (#{artist}) - #{album}"

if message.size > 140 || album.nil? || album.empty?
  message = "♫▶︎ #{name} (#{artist})"
end

logger.post(*[ENV['LF_TAG'] || 'lastfm',
  message: message,
  name: name,
  artist: artist,
  album: album,
].tap{ |_| p _ })

File.write marker, "#{latest_mark}\n"
