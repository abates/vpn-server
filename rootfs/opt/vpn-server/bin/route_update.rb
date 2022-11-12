#!/usr/bin/env ruby

CCD="/etc/openvpn/ccd"
@cn=ENV["X509_0_CN"]
@dev=ENV["dev"]

def routes
  if File.exist?("#{CCD}/#{@cn}")
    File.read("#{CCD}/#{@cn}").split(/\n/).select { |line| line =~ /^\s*iroute/ }.map { |line| line.sub(/^iroute\s+/, "").split(/\s+/) }
  else
    []
  end
end

case ARGV[0]
when "connect"
  routes.each do |route|
    puts "Adding route #{route[0]} netmask #{route[1]} via #{@dev}"
    `/sbin/route add -net #{route[0]} netmask #{route[1]} dev #{@dev}`
    `/sbin/ip rule add from #{route[0]}/#{route[1]} lookup extranet-gw`
  end
when "disconnect"
  routes.each do |route|
    puts "Removing route #{route[0]} netmask #{route[1]}"
    `/sbin/route del -net #{route[0]} netmask #{route[1]}`
    `/sbin/ip rule del from #{route[0]}/netmask #{route[1]} lookup extranet-gw`
  end
else
  STDERR.puts "Don't know what command #{ARGV[0]} means"
end
