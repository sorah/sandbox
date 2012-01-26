require 'pstore'
require 'open-uri'

def fm(tf)
  t = tf.to_i
  h = (t/60/60)
  m = (t/60)%60
  s = (t % 60)

  h = "0#{h}" if h < 10
  m = "0#{m}" if m < 10
  s = "0#{s}" if s < 10

  "#{h}h#{m}m#{s}s"

end

class Time; def to_s; self.strftime("%Y/%m/%d %R"); end; alias inspect to_s; end

db = PStore.new("/tmp/redmine.db")

db.transaction do
  db[:since] ||= Time.now
  db[:alive] = true if db[:alive].nil?
  db[:reason] ||= "initial"
  begin
    open("http://redmine.ruby-lang.org/"){|io|io.read}
    #open("http://hi/"){|io|io.read}
  rescue Exception => e
      reason = "#{e.class}: #{e.message}"

      if db[:alive] || reason != db[:reason]
        a = "redmine.r.o is down since #{Time.now} - #{reason}"
        if db[:previous] && !db[:previous][:alive]
          a += "; last down is #{fm(Time.now-db[:previous][:end])} ago"
        end
        puts a
      end


      db[:since] = Time.now
      db[:reason] = reason
      db[:alive] = false
  else
      unless db[:alive]
        a = "redmine.r.o is up. Downed time: #{fm(Time.now-db[:since])} since #{db[:since]}"
        puts a

        db[:previous] = { since: db[:since],
                          reason: db[:reason],
                          end: Time.now}
      end

      db[:since] = nil
      db[:alive] = true
      db[:reason] = nil
  end
end
