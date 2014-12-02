require 'net/http'
require 'json'
require 'uri'
p :hi

ENDPOINT = URI.parse 'http://gj.kosendj-bu.in/gifs'

def send_gifs(gifs, immediate: false)
  return unless gifs
  return if gifs.empty?

  urls = gifs.map do |f|
    "http://sorah-gif:8080/" + File.basename(f.chomp)
  end

  puts(immediate ? "IMMEDIATE SEND:" : "SEND:")
  puts urls
  Net::HTTP.start(ENDPOINT.host, ENDPOINT.port) do |http|
    r = Net::HTTP::Post.new(ENDPOINT.path)
    r['Content-Type'] = 'application/x-www-form-urlencoded'
    payload = "dj=#{immediate ? 'true' : 'false'}"
    payload << (urls.map do |x|
      "&urls[]=#{URI.encode_www_form_component(x)}"

    end.join)
    puts payload
    r.body = payload
    res = http.request(r)
    p res
  end
end

$stdin.each_line do |l|
  urls = l.sub(/\s+$/,'').split(/\s+/).map do |f|
    "http://sorah-gif:8080/" + File.basename(f.chomp)
  end

  send_gifs urls
  puts ":+1:"
end
