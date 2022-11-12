#!/usr/bin/env ruby

require "ipaddr"

HOSTS_FILE="/etc/static_hosts"
PID_FILE="/var/run/dnsmasq/dnsmasq.pid"
SERVICE_CMD="/usr/sbin/service dnsmasq restart"

def edit_hosts &block
  File.open(HOSTS_FILE) do |oldfile|
    File.open "#{HOSTS_FILE}.new", "w" do |newfile|
      block.call(oldfile, newfile) unless block.nil?
    end
  end
  File.rename("#{HOSTS_FILE}.new", HOSTS_FILE)
  dnsmasq_pid = File.read(PID_FILE).strip.to_i
  STDERR.print "Restarting dnsmasq (#{dnsmasq_pid})"
  msg = `#{SERVICE_CMD}`
  rv = $?.to_i
  if rv != 0
    STDERR.puts "FAILED #{rv}"
  else 
    STDERR.puts "SUCCESS"
  end 
end

def add_record new_hostname, new_ip
  edit_hosts do |oldfile, newfile|
    found = false
    oldfile.each do |line|
      (ipstring, existing_hostname) = line.strip.split(/\s+/)
      existing_ip = IPAddr.new(ipstring)
      if existing_ip.to_i == new_ip.to_i
        newfile.puts "#{new_ip.to_s}\t#{new_hostname}"
        found = true
      else 
        newfile.puts "#{existing_ip.to_s}\t#{existing_hostname}"
      end
    end
    if !found
      newfile.puts "#{new_ip.to_s}\t#{new_hostname}"
    end
  end
end
 
def remove_record old_hostname
  edit_hosts do |oldfile, newfile|
    oldfile.each do |line|
      (ipstring, hostname) = line.strip.split(/\s+/)
      unless old_hostname == hostname
        newfile.puts "#{ipstring}\t#{hostname}"
      end
    end
  end
end

hostname="#{ENV["X509_0_CN"]}"
ip=ENV["ifconfig_pool_remote_ip"]

case ARGV[0]
when "connect"
  STDERR.puts "Adding #{hostname}/#{ip} to DNS"
  add_record hostname, IPAddr.new(ip)
when "disconnect"
  STDERR.puts "Removing #{hostname}/#{ip} from DNS"
  remove_record hostname
else
  STDERR.puts "Don't know what command #{ARGV[0]} means"
end

