#-*- coding: utf-8 -*-
require 'net/http'
require 'json'
require 'uri'
require 'cgi'
require 'kconv'
require 'rubytter'


uri = URI.parse('http://stream.twitter.com/1/statuses/filter.json')


Net::HTTP.start(uri.host,80) do |h|
    q = Net::HTTP::Post.new(uri.request_uri)
    q.basic_auth(ARGV[0],ARGV[1])
    h.request(q,'follow=' + Rubytter.new(ARGV[0],ARGV[1]).friends_ids(ARGV[0]).join(',')) do |r|
        r.read_body do |b|
            j = JSON.parse(b) rescue puts b
            puts j["text"] if j["text"]
        end
    end
end
