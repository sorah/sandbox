require 'net/http'
require 'json'
require 'uri'

abort 'usage: sample_api.rb username password' unless ARGV.length >= 2

uri = URI.parse('http://stream.twitter.com/1/statuses/sample.json')

Net::HTTP.start(uri.host,80) do |h|
    q = Net::HTTP::Get.new(uri.request_uri)
    q.basic_auth(ARGV[0],ARGV[1])
    h.request(q) do |r|
        r.read_body do |b|
            j = JSON.parse(b) rescue next
            puts j["text"] if j["text"]
        end
    end
end
