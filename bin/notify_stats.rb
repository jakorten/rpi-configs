#!/usr/bin/env ruby
# coding: UTF-8

# notify_stats.rb
# 
# notify about current status of raspberry pi
# 
# created on : 2012.05.31
# last update: 2012.06.14
# 
# by meinside@gmail.com

require "rubygems"
require "gmail"	# gem install mime ruby-gmail (https://github.com/dcparker/ruby-gmail)
require "yaml"

CONFIG_FILEPATH = File.join(File.dirname(__FILE__), "configs.yml")

DEFAULT_MAIL_TITLE = "Current Status of Raspberry Pi"
RASPI_LOGO_IMG_URL = "http://www.raspberrypi.org/wp-content/uploads/2012/03/Raspi_Colour_R.png"
RASPI_URL = "http://raspberrypi.org/"

def read_configs
	if File.exists? CONFIG_FILEPATH
		File.open(CONFIG_FILEPATH, "r"){|file|
			begin
				return YAML.load(file)
			rescue
				puts "* error parsing config file: #{CONFIG_FILEPATH}"
			end
		}
	else
		puts "* config file not found: #{CONFIG_FILEPATH}"
	end
	return nil
end

def send_gmail(configs, title, text_content, html_content)
	Gmail.new(configs["gmail_sender"]["username"], configs["gmail_sender"]["passwd"]) {|gmail|
		gmail.deliver {
			to configs["notification_recipient"]["email"]
			subject title
			if text_content
				text_part {
					body text_content
				}
			end
			if html_content
				html_part {
					content_type 'text/html; charset=UTF-8'
					body html_content
				}
			end
		}
	}
end

def get_current_ip
	if `/sbin/ifconfig eth0` =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
		return $1.strip
	end
	return nil
end

def get_current_storage
	return `df -h`.strip
end

def get_current_memory
	return `free`.strip
end

def get_uptime
	return `uptime`.strip
end

def get_uname
	return `uname -a`.strip
end

def decorate(title, content)
	return "<p><b>* #{title}:</b><br/>#{content.gsub("\n", "<br/>")}</p><hr/>"
end

if __FILE__ == $0

	title = ARGV.count > 0 ? ARGV.join(" ") : DEFAULT_MAIL_TITLE

	current_ip = get_current_ip
	if current_ip
		content = []

		# uname
		content << decorate("System", get_uname)

		# uptime
		content << decorate("Uptime", get_uptime)

		# ip
		content << decorate("IP", current_ip)

		# storage
		content << decorate("Free Storage", get_current_storage)

		# memory
		content << decorate("Free Memory", get_current_memory)

		# footer
		content << "<p><a href='#{RASPI_URL}'><img src='#{RASPI_LOGO_IMG_URL}' width='50px' alt='Logo'/></a>&nbsp;<i>This email was sent at #{Time.now.strftime("%Y-%m-%d %H:%M")}, using: #{__FILE__}</i></p>"

		# send result
		send_gmail(read_configs, title, nil, content.join(""))
	end

end
