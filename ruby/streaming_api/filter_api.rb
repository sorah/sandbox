#-*- coding: utf-8 -*-
require 'net/http'
require 'json'
require 'uri'
require 'cgi'
require 'kconv'

abort 'usage: sample_api.rb username password keyword[,keyword,...]' unless ARGV.length >= 3

uri = URI.parse('http://stream.twitter.com/1/statuses/filter.json')

user, pass = ARGV[0..1]
user, pass = File.read(pass) \
                 .split(/\r?\n/) if /^--file/ =~ user


Net::HTTP.start(uri.host,uri.port) do |h|
    q = Net::HTTP::Post.new(uri.request_uri)
    q.basic_auth(user,pass)
    h.request(q,'track=' + CGI.escape(ARGV[2].toutf8)) do |r|
        buf = []
        r.read_body do |b|
            buf << b.chomp unless b.chomp.empty?
            j = JSON.parse(buf.join) rescue next
            buf = []
            if j["text"] && j["user"] && j["user"]["screen_name"]
              puts "#{j["user"]["screen_name"]}: #{j["text"]}"
            else
              p j
            end
        end
    end
end
