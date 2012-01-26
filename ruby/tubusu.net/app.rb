#-*- coding: utf-8 -*-
require 'rubygems'
require 'punycode'
require 'sinatra'

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

get '/' do
	@after =""
  @who = request.host.gsub(/^(.+?)\..+$/) {|s| name = $1; name =~ /^xn--(.+)/ ? (Punycode.decode($1) rescue name) : name }
	@who = case @who
				 when /(w+)/
					 @after = $1
					 @who.gsub(/w+/,"")
				 else
					 @who
				 end
  @why = nil
  erb :index
end

get '/:why' do
	@after =""
  @who = request.host.gsub(/^(.+?)\..+$/) {|s| name = $1; name =~ /^xn--(.+)/ ? (Punycode.decode($1) rescue name) : name }
	@who = case @who
				 when /(w+)/
					 @after = $1
					 @who.gsub(/w+/,"")
				 else
					 @who
				 end
	@why = params[:why]
  erb :index
end

__END__

@@index
<html>
<head>
<title><%=h @who%> 潰す!!!</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</head>
<body>
<h1><%=h @who%> 潰す!!!<%=h @after %></h1>
<% if @why %>
  <p>理由は以下の通りです: </p>
  <p><%=h @why%></p>
<% end %>
<hr>
<p style="font-size: 10px">(このサイトの内容はネタです。本気にして通報などはしないでください!!!!!)</p>
<p style="font-size: upx">Author: Sora Harakami</p>
</body>
</html>
