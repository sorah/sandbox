#!/usr/bin/env ruby
require 'aws-sdk'
require 'open-uri'
require 'shellwords'

class CommandFailed < StandardError; end

def cmd(*args)
  puts "==> #{args.shelljoin}"
  system(*args) or raise CommandFailed
end

def regions
  @regions ||= @ec2.describe_regions.regions.map(&:region_name)
end

IFACE = 'vxlan0'
VXLANID = 10

@region = open('http://169.254.169.254/latest/meta-data/placement/availability-zone', &:read).chomp[0..-2]
@instance_id = open('http://169.254.169.254/latest/meta-data/instance-id', &:read).chomp

@ec2 = Aws::EC2::Client.new(region: @region)
@instance = @ec2.describe_instances(
  instance_ids: [@instance_id]
).reservations[0].instances[0]

@vxlan = @instance.tags.find { |_| _.key == 'Vxlan' }&.value
@vxlan_ip = @instance.tags.find { |_| _.key == 'VxlanIp' }&.value

unless @vxlan
  abort "No 'Vxlan' tag found for this instance #{@instance_id}"
end
unless @vxlan_ip
  abort "No 'VxlanIp' tag found for this instance #{@instance_id}"
end

default_route IO.popen(%w(ip r get 8.8.8.8), 'r', &:read)
main_iface = default_route.match(/dev ([^ ]+)/)&.to_a.fetch(1)
default_gateway = default_route.match(/via ([^ ]+)/)&.to_a.fetch(1)

instances = regions.map do |region|
  Thread.new do
    ec2 = Aws::EC2::Client.new(region: region)
    ec2.describe_instances(
      filters: [
        {name: 'tag:Vxlan', values: [@vxlan]},
      ]
    ).reservations.flat_map(&:instances).map do |instance|
      [region, instance]
    end
  end
end.flat_map(&:value)

unless File.exist?("/sys/class/net/#{IFACE}")
  cmd(*%w(ip link add), IFACE, *%w(type vxlan id), VXLANID.to_s, 'dev', main_iface, 'dstport', '4789')
  cmd(*%w(ip link set mtu), (1500-50).to_s, 'dev', IFACE) # MTU of inter-region pcx is 1500, VXLAN overhead is 50
  cmd(*%w(ip link set up dev), IFACE)
  puts "==> /proc/sys/net/ipv4/conf/#{IFACE}/forwarding = 1"
  File.write "/proc/sys/net/ipv4/conf/#{IFACE}/forwarding", '1'
  puts "==> /proc/sys/net/ipv6/conf/#{IFACE}/forwarding = 1"
  File.write "/proc/sys/net/ipv6/conf/#{IFACE}/forwarding", '1'

end

if IO.popen([*%w(ip -o a show dev), IFACE], 'r', &:read).each_line.grep(/inet /).empty?
  cmd(*%w(ip addr add), @vxlan_ip, 'dev', IFACE)
end

fdb = IO.popen([*%w(bridge fdb show dev), IFACE], 'r', &:read).each_line.map do |l|
  m = l.chomp.match(/^(00:00:00:00:00:00) .*dst ([^ ]+)/)
  next nil unless m
  [m[2], m[1]]
end.compact.to_h

fdb_to_retain = {@instance.private_ip_address => true, '127.0.0.1' => true}
instances.each do |(_region, instance)|
  ip = instance.private_ip_address
  next if ip == @instance.private_ip_address
  unless fdb[ip]
    cmd(*%w(ip route add), "#{ip}/32", 'via', default_gateway)
    cmd(*%w(bridge fdb append to 00:00:00:00:00:00 dst), ip, 'dev', IFACE)
  end
  fdb_to_retain[ip] = true
end

fdb.each do |ip, _|
  next if fdb_to_retain[ip]
  cmd(*%w(ip route del), "#{ip}/32", 'via', default_gateway)
  cmd(*%w(bridge fdb del 00:00:00:00:00:00 dst), ip, 'dev', IFACE)
end
