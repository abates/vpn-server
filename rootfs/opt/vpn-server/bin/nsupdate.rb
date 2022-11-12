#!/usr/bin/env ruby

require 'tempfile'

@dns_server="172.16.2.100"
@fwd_zone="home.omeganetserv.com"
@rev_zone="16.172.in-addr.arpa"
@nsupdate_opts="-k /etc/openvpn/Kopenvpn.+157+02813.private"

@cn=ENV["X509_0_CN"]
@ip=ENV["ifconfig_pool_remote_ip"]

def add_record zone, hostname, address, type, ttl
  Tempfile.open "nsupdate" do |f|
    f.puts "server #{@dns_server}"
    f.puts "zone #{zone}"
    f.puts "update delete #{hostname}. #{type}"
    f.puts "update add #{hostname}. #{ttl} #{type} #{address}"
    f.puts "send"
    f.close
    STDERR.puts "nsupdate #{@nsupdate_opts} #{f.path}"
    STDERR.puts `nsupdate #{@nsupdate_opts} #{f.path}`
  end
end
 
def remove_record zone, hostname, type
  Tempfile.open "nsupdate" do |f|
    f.puts "server #{@dns_server}"
    f.puts "zone #{zone}"
    f.puts "update delete #{hostname}. #{type}"
    f.puts "send"
    f.close
    STDERR.puts "nsupdate #{@nsupdate_opts} #{f.path}"
    STDERR.puts `nsupdate #{@nsupdate_opts} #{f.path}`
  end
end

case ARGV[0]
when "connect"
  STDERR.puts "Adding #{@cn}/#{@ip} to DNS"
  add_record @fwd_zone, "#{@cn}.#{@fwd_zone}", @ip, "A", 600
  add_record @rev_zone, "#{@ip.split(/\./).reverse.join(".")}.in-addr.arpa", "#{@cn}.#{@fwd_zone}", "PTR", 600
when "disconnect"
  STDERR.puts "Removing #{@cn}/#{@ip} from DNS"
  remove_record @fwd_zone, "#{@cn}.#{@fwd_zone}", "A"
  remove_record @rev_zone, "#{@ip.split(/\./).reverse.join(".")}.in-addr.arpa", "PTR"
else
  STDERR.puts "Don't know what command #{ARGV[0]} means"
end
