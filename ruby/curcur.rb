a = ['\\','|','/','-']
s = nil
loop do
  a.each do |x|
    print "\b" unless s.nil?
    s = true
    print x
    sleep 0.2
  end
end

