#!/usr/bin/env ruby
require 'yaml'
require 'socket'

def prepare
  load_config
  failure = test_config
  if failure
    $stderr.puts
    $stderr.puts "---- !!! test failed !!! ----"
    $stderr.puts failure
    $stderr.puts "-----------------------------"
    $stderr.puts
    return false
  end
  unless listen_ports
    return false
  end
  true
end

def load_config
  @config = YAML.load_file(ARGV[0])

  @proxy = @config[:command]
  @check = @config[:check]
end

def listen_ports
  @ports ||= {}
  new_ports = {}
  ports_to_close = []

  @config[:ports].each do |fd, bind|
    fd = fd.to_i
    new_port = {bind: [bind[:host], bind[:port].to_i]}

    if @ports[fd]
      if @ports[fd][:bind] == new_port[:bind]
        new_ports[fd] = @ports[fd]
      else
        ports_to_close << [fd, @ports[fd]]
        new_ports[fd] = new_port
      end
    else
      new_ports[fd] = new_port
    end
  end

  @ports.each do |fd, port|
    if !new_ports[fd] && port[:server]
      ports_to_close << [fd, port]
    end
  end

  new_servers = []
  new_ports.each do |fd, port|
    unless port[:server]
      port[:server] = TCPServer.new(*port[:bind])
      $stderr.puts "---- > listening #{port[:bind].inspect} (fd@#{port[:server].fileno}, childfd@#{fd})"
      new_servers << [fd, port]
    end
  end

  ports_to_close.each do |(fd,port)|
    $stderr.puts "---- > closing #{port[:bind].inspect} (fd@#{port[:server].fileno}), childfd@#{fd})"
    port[:server].close
  end

  @ports = new_ports

  return true
rescue Exception => e
  $stderr.puts "---- ! #{e.inspect}"
  $stderr.puts "\t#{e.backtrace.join("\n\t")}"

  if new_servers
    new_servers.each do |(fd,port)|
      if port[:server] && !port[:server].closed?
        $stderr.puts "---- > closing #{port[:bind].inspect} (fd@#{port[:server].fileno}), childfd@#{fd}; rolling back)"
        port[:server].close
      end
    end
  end
  return false
end

def test_config
  dummy_server = TCPServer.new('localhost', 0)
  fds = {err: [:child, :out]}
  @config[:ports].keys.each do |fd|
    fds[fd] = dummy_server.fileno
  end
  IO.popen([*@check, fds], 'r') do |io|
    out = io.read
    pid, status = Process.waitpid2(io.pid)

    status.success? ? nil : out
  end
ensure
  if dummy_server && !dummy_server.closed?
    dummy_server.close
  end
end

def send_signal(signal, pids)
  pids.each do |desc,pid|
    return unless pid

    $stderr.puts "---- Sending #{signal} to#{desc && " #{desc} "}pid #{pid}"
    begin
      Process.kill(signal, pid)
    rescue Errno::ESRCH => e
      $stderr.puts "---- ! e.inspect"
    end
  end
end

def spawn_proxy
  fds = Hash[@ports.map { |fd, config| [fd, config[:server].fileno] }]
  pid = spawn(*@proxy, fds)
  $stderr.puts "---- > spawned pid #{pid}"
  pid
end

shutting_down = false
active_pid = nil
next_pid = nil

terminate = proc do
  shutting_down = true
  $stderr.puts "---- immediately terminate..."
  send_signal :TERM, active: active_pid, next: next_pid
end

shutdown = proc do
  shutting_down = true
  $stderr.puts "---- graceful shutdown..."
  send_signal :USR1, active: active_pid, next: next_pid
end

reload = proc do
  if next_pid
    $stderr.puts "---- ! oops, there's ongoing reload? (active: #{active_pid}, next: #{next_pid})"
  else
    $stderr.puts "---- graceful restarting... (active: #{active_pid})"

    unless prepare
      $stderr.puts "---- ! restart cancelled."
      next
    end

    next_pid = spawn_proxy
    sleep 1

    send_signal(:USR1, active: active_pid)
    _, status = Process.waitpid2(active_pid)

    active_pid, next_pid = next_pid, nil

    $stderr.puts "---- > reloaded (active: #{active_pid})"
  end
end

trap(:TERM, terminate)
trap(:INT,  terminate)
trap(:USR1, shutdown)
trap(:HUP,  reload)

#####

exit 1 unless prepare
active_pid = spawn_proxy

#####

loop do
  break if shutting_down

  begin
    wpid = active_pid
    pid, status = Process.waitpid2(wpid)
    $stderr.puts "---- active pid #{pid} stopped: #{status.inspect}"
  rescue Errno::ECHILD
  end

  if wpid == active_pid
    $stderr.puts "---- ! oh, it seems down..."
    exit status.exitstatus || 128
  end
end