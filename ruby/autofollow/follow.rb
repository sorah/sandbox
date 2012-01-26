# follow.rb - (Twitter) Auto follow other user's following users
# Author: Sora harakami <sora134[at]gmail.com>
# Licence: MIT licence
#  The MIT Licence {{{
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
#  }}}
#
# usage:
#   follow.rb <username>

require 'oauth'
require "rubytter"
require "yaml"
require 'highline'

abort "usage: follow.rb <username>" unless ARGV[0]

#oauth-patch.rb http://d.hatena.ne.jp/shibason/20090802/1249204953
if RUBY_VERSION >= '1.9.0'
  module OAuth
    module Helper
      def escape(value)
        begin
          URI::escape(value.to_s, OAuth::RESERVED_CHARACTERS)
        rescue ArgumentError
          URI::escape(
            value.to_s.force_encoding(Encoding::UTF_8),
            OAuth::RESERVED_CHARACTERS
          )
        end
      end
    end
  end

  module HMAC
    class Base
      def set_key(key)
        key = @algorithm.digest(key) if key.size > @block_size
        key_xor_ipad = Array.new(@block_size, 0x36)
        key_xor_opad = Array.new(@block_size, 0x5c)
        key.bytes.each_with_index do |value, index|
          key_xor_ipad[index] ^= value
          key_xor_opad[index] ^= value
        end
        @key_xor_ipad = key_xor_ipad.pack('c*')
        @key_xor_opad = key_xor_opad.pack('c*')
        @md = @algorithm.new
        @initialized = true
      end
    end
  end
end

CONSUMER = {
  :key => "x9wuA4TOYcVo8aMj31jHYQ",
  :secret => "nF7IhuFkAt2ZAg4uAJHLDmtAOmwhbjQoiJM5lQ2en8"
}
site = "http://twitter.com" 
cons = OAuth::Consumer.new(CONSUMER[:key],CONSUMER[:secret], :site => site)


request_token = cons.get_request_token
puts "Access This URL and press 'Allow' => #{request_token.authorize_url}"
pin = HighLine.new.ask('Input key shown by twitter: ')
access_token = request_token.get_access_token(
  :oauth_verifier => pin
)
keys = [access_token.token,access_token.secret]

token = OAuth::AccessToken.new(cons, keys[0], keys[1])

puts "--------------------------------------------------------"


t = OAuthRubytter.new(token)

f = t.friends_ids(ARGV[0])
ff = t.friends_ids(ARGV[1])
$i = 0

f.each do |u|
    begin
        unless ff.include?(u)
            t.follow(u) 
            puts "follow: "+u.to_s
            $i += 1
        end
    rescue Rubytter::APIError => e
        if /You are unable to follow more people at this time/ =~ e.to_s || /You have been blocked from following this account at the request of the user./ =~ e.to_s
            puts "ERROR: Could not follow user - You are unable to follow more people at this time."
            puts "------"
            puts "Total followed: "+$i.to_s
            puts "Sleep 600 sec"
            sleep 600
        end
        puts "error : " + e.inspect
    rescue => e
        puts "Ruby error : " + e.inspect
    end
end

puts "------"
puts "Total followed: "+$i.to_s

