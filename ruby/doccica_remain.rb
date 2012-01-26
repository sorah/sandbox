#-*- coding: utf-8 -*-
require "net/https"
require "kconv"
http = Net::HTTP.new('ec.bmobile.ne.jp',443)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
ho = http.start do |f|
    f.get('/ecom/RegLogin')
end
h = ho.body.toutf8

if ho.code != '200'
    puts "Not available"
else
    ea = h.scan(/<b>ご利用終了日：<\/b>([0-9]+)年([0-9]+)月([0-9]+)日/).flatten
    puts "Remain Time: "+h.scan(/<b>残り時間：<\/b>([0-9]+)分/u).flatten[0]
    puts "Expire at: "+ea[0]+"/"+ea[1]+"/"+ea[2]
end
