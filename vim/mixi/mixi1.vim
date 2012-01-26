" yet another mixi.vim - support for japanese cozy social networking system
" Version: 1
" Author: sorah <http://codnote.net>
" [REQUIRE]
"   - library wsse (gem install wsse)
"   - +ruby
" [NEW POST]
"   `:Mixi`
"   Title is line 1.
"   Then, run :PostMixi or :w to post.
" [POST]
"   `:PostMixi`
" [CONFIG]
"  `~/.mixi`
"  line 1: mixi mail address
"  line 2: mixi password
"  line 3: mixi member id (so number)
" [MIXI ECHO & IMAGE]
"   never not supported.
"   sorry :(

"command! w :call <SID>MixiStart()
command! Mixi :call <SID>MixiStart()

function! s:MixiStart()
  ruby mixi_run
endfunction

ruby << EOF
class Mixi
  def initialize(email, password, mixi_premium)
    require 'kconv'
    require 'rubygems'
    require 'wsse'
    require 'net/http'
    @email, @password, @mixi_premium =
      email, password, mixi_premium
  end

  def post(title, summary)
    site = 'mixi.jp'
    content =<<__XML__
<?xml version='1.0' encoding='utf-8'?>
<entry xmlns='http://purl.org/atom/ns#'>
<title>#{title}</title>
<summary>
#{summary}
</summary>
</entry>
__XML__
    Net::HTTP.start(site,80) do |h|
        h.post('/atom/diary/member_id='+@mixi_premium,content,{'X-WSSE'=>WSSE::header(@email,@password)})
    end
  end
end

def create_mixi_instance
  # ~/.mixi
  # line1: input your email
  # line2: input your password
  # line3: input your member-id
  if File.exist?(File.expand_path('~/.mixi'))
    mixi_config = File.read(File.expand_path('~/.mixi'))
    email, password, premium = mixi_config.split(/\r?\n/)
    Mixi.new email, password, premium
  else
    m = Mixi.new 'YOUR_EMAIL', 'YOUR_PASSWORD', 'YOUR_MEMBERID'
  end
end

def mixi_run
  vim = VIM::Buffer.current
  return if VIM.evaluate('confirm("really?")') == 0

  endline = VIM.evaluate %[line("$")]
  title   = VIM.evaluate %[getline(1)]
  body = VIM.evaluate(%[getline(2, #{endline})])

  m = create_mixi_instance
  m.post title, body
end
EOF
