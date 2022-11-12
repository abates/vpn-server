#!/usr/bin/env ruby

require "open3"

OPENVPN_DIR="/etc/openvpn"

vpn = ARGV[0]
script_dir="#{OPENVPN_DIR}/#{vpn}-scripts-enabled"

def log msg
  now=Time.now.strftime("%a %b %_m %H:%M:%S %Y")
  client="#{ENV["X509_0_CN"]}/#{ENV["trusted_ip"]}/#{ENV["trusted_port"]}"
  STDERR.puts "#{now} #{client} #{msg}"
end

action = ENV["script_type"]

if action == "client-connect"
  action = "connect"
elsif action == "client-disconnect"
  action = "disconnect"
else
  log "Don't know what the action is for #{ENV['script_type']}"
  exit 0
end

log "Running init scripts"
SCRIPT_DIR = "/etc/openvpn/server/#{File.basename(ENV["config"], ".conf")}_scripts-enabled/"
Dir.entries(SCRIPT_DIR).sort.each do |script|
  script_path = "#{SCRIPT_DIR}/#{script}"
  next if script == "." or script == ".."
  next unless File.executable?(script_path)

  begin
    Open3.popen2e("#{script_path} #{action} #{ARGV.last}") do |stdin, stdout, wait_thr|
      stdout.each do |msg|
        log "#{script} #{action} #{msg}"
      end
    end
  rescue => ex
    log "Failed to execute #{script_path}: #{ex}"
  end
end
