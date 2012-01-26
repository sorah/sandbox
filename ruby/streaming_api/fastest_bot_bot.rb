#-*- coding: utf-8 -*-
require 'net/http'
require 'json'
require 'uri'
require 'cgi'
require 'kconv'
require 'rubytter'
require 'thread'
abort 'usage: sample_api.rb username password' unless ARGV.length >= 2

t = Rubytter.new(ARGV[0],ARGV[1])


Thread.new{
        5.times do 
            puts "wait..."
            sleep 1
        end
        s = "@fastest_bot hi! (#{rand(600).to_s})"
        puts s
        t.update(s) 
}


uri = URI.parse('http://stream.twitter.com/1/statuses/filter.json')

Net::HTTP.start(uri.host,80) do |h|
    q = Net::HTTP::Post.new(uri.request_uri)
    q.basic_auth(ARGV[0],ARGV[1])
    param = 'track=' + CGI.escape(('@'+ARGV[0]).toutf8)

    h.request(q,param) do |r|
        r.read_body do |b|
            j = JSON.parse(b) rescue next
            puts j["text"] if j["text"]
            if "fastest_bot" == j["user"]["screen_name"]
                s = "@fastest_bot hi! (#{rand(600).to_s})"
                puts s
                t.update(s)
            end
        end
    end
end
