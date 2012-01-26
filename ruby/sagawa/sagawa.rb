#-*- coding: utf-8 -*-
require 'rubygems'
require 'net/http'
require 'hpricot'
require 'kconv'
require 'cgi'

class String
    def unescape_html
        CGI.unescapeHTML(self)
    end
end

class Sagawa
    def initialize(tracking_no)
        Net::HTTP.version_1_2

        n = Hpricot( Net::HTTP.start('k2k.sagawa-exp.co.jp', 80) do |h|
            h.post('/p/web/okurijosearch.do',
                  'okurijoNo='+tracking_no.to_s).body.unescape_html.toutf8
        end )
        @latest_activity = n.search("td.ichiran-fg2")[6].inner_text
        @detail = n.search("td.ichiran-fg2")[24].inner_text.gsub(/^\s+/,"")
        @pickuped_point = ""
        @destination_point = ""
        raise ArgumentError, "Wrong tracking_no" if /お問い合わせNo.をお確かめ下さい。/u =~ @detail
    end

    attr_reader :detail, :latest_activity
end

if $0 == __FILE__
  (puts "usage: sagawa.rb TRACKING_NUMBER";exit) unless ARGV[0]

  sagawa = SagawaTracking.new(ARGV[0])

  puts sagawa.latest_activity
  puts "----"
  puts sagawa.detail
end
