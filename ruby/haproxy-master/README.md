## Features

- haproxy master script with graceful restarting without SO_REUSEPORT
- validate configuration before restarting
- removing + adding + changing listening port
  - safely rollback when something failed

## How it works

- run.rb creates server sockets
- run.rb spawns haproxy
- haproxy binds to fd given by run.rb
- run.rb rotates haproxy

## Example

- `haproxy.cfg`
- `run.yml`

### Test server

```
ruby -rsocket -e 'srv = TCPServer.new("127.0.0.1",18080); i=0; while sock = srv.accept; i += 1; Thread.new(sock){|s| nil until 
s.gets.chomp.chomp.empty?; s.puts "HTTP/1.1 200 OK\r\n\r\n#{p("#{Time.now},#{i}")}"; s.close }; end'
```

### Test client

```
ruby -ropen-uri -e'loop { begin; p open("http://localhost:8080", "r", &:read); sleep 0.01; rescue Interrupt; exit; rescue Exception => e; p $!; sleep 1;  end }'
```