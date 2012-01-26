require 'readline'

Thread.new do
  loop do
    print "\e[0G" + "\e[K"
    p Time.now
    p Time.now
    p Time.now
    p Time.now
    p Time.now
    Readline.refresh_line
    sleep 3
  end
end
while s = Readline.readline(">")
  puts "=>#{s}"
end

