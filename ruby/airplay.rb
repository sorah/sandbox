require 'socket'
require 'securerandom'
 
session = SecureRandom.uuid
 
TCPSocket.open('192.168.1.222', 7000) do |io|
  payload = <<-EOF
Content-Location: #{ARGV[0]}
Start-Position: 0
EOF
 
  request = <<-EOF
POST /play HTTP/1.1
User-Agent: MediaControl/1.0
Content-Length: #{payload.size}
X-Apple-Session-ID: #{session}
 
#{payload}
EOF
 
puts request
  io.puts request
 
  Thread.new do
    loop do
      io.puts <<-EOF
GET /scrub HTTP/1.1
User-Agent: MediaControl/1.0
X-Apple-Session-ID: #{session}
 
EOF
      sleep 10
    end
  end
 
  Thread.new do
    sleep 2
    TCPSocket.open('192.168.1.222', 7000) do |io2|
      io2.puts <<-EOF
POST /reverse HTTP/1.1
Upgrade: PTTH/1.0
Connection: Upgrade
X-Apple-Purpose: event
Content-Length: 0
User-Agent: MediaControl/1.0
X-Apple-Session-ID: #{session}
 
      EOF
 
      while buf = io2.gets
        p [:event,buf]
      end
      p [:event, :closed]
    end
  end
 
  while buf = io.gets
    p [:main,buf]
  end
end
