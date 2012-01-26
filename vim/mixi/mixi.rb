# -*- coding: utf-8 -*-
# Yet another mixi.rb - support the mixi.vim (ver2)
# Author: Sora Harakami <sora134[at]gmail.com>
# Licence: MIT Licence
# Detail: README.mkd

require 'rubygems'
require 'net/http'

class Mixi
    @@site = 'mixi.jp'

    def initialize(email, password, mixi_member_id)
        @email, @password, @mixi_member_id =
            email, password, mixi_member_id
    end

    def post(h={})
    end

end

class MixiApi < Mixi
    def post(h={})
        require 'wsse'
        content = <<-__XML__.gsub(/^\s*\|/,"")
            |<?xml version='1.0' encoding='utf-8'?>
            |<entry xmlns='http://purl.org/atom/ns#'>
            |<title>#{h[:title].chomp}</title>
            |<summary>
            |#{h[:body]}
            |</summary>
            |</entry>
        __XML__
        Net::HTTP.start(@@site,80) do |h|
            h.post('/atom/diary/member_id='+@mixi_member_id, content,
                   {'X-WSSE' => WSSE::header(@email, @password)})
        end
    end
end

class MixiHtml < Mixi
    def post(hh={})
        h = {:publish_range => 'default'}.merge(hh)
        raise ArgumentError, 'publish_range is invaid!' unless ['mymixi','2mymixis','all','me_only','default','open','close','friend','friend_friend','2friends','public','not_public'].include?(h[:publish_range])

        require 'mechanize'
        mixi_top = 'http://'+@@site+'/'
        agent = WWW::Mechanize.new
        agent.get(mixi_top)

        agent.page.form_with(:name => 'login_form') do |f|
            f.field_with(:name => 'email').value = @email
            f.field_with(:name => 'password').value = @password
            f.click_button
        end

        agent.get(mixi_top + 'list_diary.pl')
        agent.page.link_with(:text => '日記を書く').click

        agent.page.form_with(:name => "diary") do |f|
            f.field_with(:name => 'diary_title').value = h[:title].chomp
            f.field_with(:name => 'diary_body').value = h[:body].chomp
            
        #'mymixi','2mymixi','all','me_only','default','open','close','friend','friend_friend','2friend'
            case h[:publish_range]
            when 'mymixi','friend'
                f.radiobutton_with(:name => 'diary_level_type', :value => 'friend').check
            when '2mymixis','friend_friend','2friends'
                f.radiobutton_with(:name => 'diary_level_type', :value => 'friend_friend').check
            when 'all','open','public'
                f.radiobutton_with(:name => 'diary_level_type', :value => 'open').check
            when 'me_only','close','not_public'
                f.radiobutton_with(:name => 'diary_level_type', :value => 'close').check
            end
            #f.button_with(:value => "入力内容を確認する").click
            f.submit
        end

        agent.page.form_with(:action => 'add_diary.pl').submit
    end
end

def mixi_ins api=true
    # ~/.mixi
    # line1: input your email
    # line2: input your password
    # line3: input your member-id
    if File.exist?(File.expand_path('~/.mixi'))
        mixi_config = File.read(File.expand_path('~/.mixi'))
        email, password, member_id = mixi_config.split(/\r?\n/)
        if api
            MixiApi.new email, password, member_id
        else
            MixiHtml.new email, password, member_id
        end
    else
        email = 'YOUR_EMAIL'
        password = 'YOUR_PASSWORD'
        member_id = 'YOUR_MEMBERID'
        if api
            MixiApi.new email, password, member_id
        else
            MixiHtml.new email, password, member_id
        end
    end
end

def mixi_post file_name
    begin
        body = File.open(file_name){ |f| f.readlines }
        title = body.shift

        if /^publish-range: / =~ title
            publish_range = title.gsub(/^publish-range: /,"").chomp
            title = body.shift
            hash = { :publish_range => publish_range, :title => title, :body => body.join("") }

            mixi = mixi_ins(hash[:publish_range] != 'default' ? false : false)
        else
            hash = { :title => title, :body => body.join("") }
            mixi = mixi_ins false
        end

        mixi.post hash
    rescue => e
        print e.inspect
    else
        print '0'
    end
end

abort "usage: mixi.rb file_name" if ARGV.empty?

mixi_post ARGV[0]
