require 'rubygems'
require 'mechanize'
require 'pstore'
#read config
mail,pass,memberid = File.read(File.expand_path("~/.mixi")).split(/\r?\n/)
db = PStore.new("/.mixi2rss.rb.tmp")
db.transaction do
    db["cache"] = [] if !db["cache"]
    ##########
    #login to mixi
    STDERR.puts "Login to mixi"
    agent = WWW::Mechanize.new
    page = agent.get('http://mixi.jp/')
    form = page.forms[0]
    form.field_with(:name => 'email').value = mail
    form.field_with(:name => 'password').value = pass
    form.field_with(:name => 'next_url').value = '/home.pl'
    page = agent.submit(form, form.buttons.first)
    #get diarylist
    STDERR.puts "Fetching diary list..."
    pdiarylist = agent.get("http://mixi.jp/new_friend_diary.pl")
    diarylist = []
    pdiarylist.search(".entryList01/li/dl/dd").each{|d|diarylist << ["http://mixi.jp/"+d.at("a")["href"],d.inner_text.gsub(/\n/,"")];STDERR.puts "Diary "+d.inner_text.gsub(/\n/,"")}
    #cache diarys
    diarylist.each do |d|
        flag = false
        db["cache"].each{|x|flag = true if x["link"] != d[0]}
        flag = true if db["cache"].length <= 0
        if flag
            STDERR.puts "Fetch "+d[1]
            page = agent.get(d[0])
            if !page.at(".messageAlert")
                diary = page.at("#diary_body").inner_text
                db["cache"] << {"link" => d[0],"title" => d[1],"body" => diary}
            end
        end
        STDERR.puts "sleeping.."
        sleep 0.6
    end
    db["cache"].each do |d|
        puts "---"
        puts d["title"]
        puts ""
        puts d["body"]
    end
end
