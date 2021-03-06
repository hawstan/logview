#!/usr/bin/env ruby

#
# Background log message viewer 
# Author		hawstan (Stanley Hawkeye)
# Date		2014-06-15
# Version		0.1
# License		GPLv2
#

require 'getoptlong'
require 'sdl'

running = true

# cease running upon catching SIGTERM
Signal.trap("TERM") do
	puts "Terminating..."
	running = false
end


opts = GetoptLong.new(
  [ '--help', GetoptLong::NO_ARGUMENT ],
  [ '--width', '-w', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--height', '-h', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--font', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--font-size', GetoptLong::REQUIRED_ARGUMENT ]
)

width = 500
height = 100

fontPath = '/usr/share/fonts/liberation/LiberationMono-Regular.ttf'
fontSize = 12

opts.each do |opt, arg|
	case opt
		when '--help'
			puts <<-EOF
Usage:
  logview LOGFILE[ options]
  logview --help	display this message and exit 
Options:
  LOGFILE		path to the file that is displayed
  --width <width>, -w <width>
			let the window width be <width>
  --height <height, -h <height>
			let the window height be <height>
  --font <path>		use the file <path> as the font
  --font-size <size>	let the font size be <size>
Signals:
  USR1			reopen LOGFILE
  TERM			soft exit
EOF
			exit(0)
		when '--width'
			width = arg.to_i
		when '--height'
			height = arg.to_i
		when '--font'
			fontPath = arg
		when '--font-size'
			fontSize = arg.to_i
	end
end

if ARGV.length < 1
  puts "Missing LOGFILE argument (see --help for more information)"
  exit 0
end

logfileName = ARGV[0]

if( not File.exists?(logfileName) )
	$stderr.puts "Log file '" + logfileName.to_s + "' doesn't exist"
#	exit
end

if( width < 1 )
	$stderr.puts "Width must be greater than 0."
	exit
end

if( height < 1 )
	$stderr.puts "Height must be greater than 0."
	exit
end

if( not File.exists?(fontPath) )
	$stderr.puts "Font file does not exist."
	exit
end

if( fontSize < 1)
	$stderr.puts "Font size must be greater than 0."
	exit
end

ONE_FRAME = 0.1

SDL.init( SDL::INIT_VIDEO )

screen = SDL::Screen.open(width, height, 16, SDL::SWSURFACE)
SDL::WM::set_caption($0,$0)

SDL::TTF.init

font = nil
begin
	font = SDL::TTF.open(fontPath, fontSize)
rescue SDL::Error => e
	$stderr.puts(e.to_s)
	exit
end
at_exit { font.close }

font.style = SDL::TTF::STYLE_NORMAL


numLines = height / font.height


def openLogFile(filename)
	begin
		return File.new(filename, "r")
	rescue SystemCallError => e
		$stderr.puts("Cannot open log file: " + e.to_s)
		exit
	end
end

file = openLogFile(logfileName)
at_exit { file.close }

# reopen log file upon catching USR1
Signal.trap("USR1") do
	puts "Reopening log file..."
	file.close
	file = openLogFile(logfileName)	
end

lines = []

while running
	startTime = Time.now

	pendingRedraw = false

	while event = SDL::Event.poll
		case event
			when SDL::Event::Quit
				exit
			else
				#TODO use (future) SDL::Event::VideoExpose
				pendingRedraw = true
		end
	end

	# check if the file has new content
	character = nil
	if((character = file.getc) != nil)
		file.ungetc(character)

		# load new lines
		while line = file.gets
			line.chomp!
			lines.unshift line
			if lines.length > numLines
				lines.pop 
			end
		end

		pendingRedraw = true
	end

	if pendingRedraw
		# clear the screen with black
		screen.fillRect(0, 0, width, height, 0x000000)

		for i in 0..(lines.length-1)
			font.draw_solid_utf8(screen, lines[i], 0, font.height * i, 255, 255, 255)
		end
		screen.flip
	end

	# make sure the frame takes at least ONE_FRAME seconds
	duration = Time.now - startTime
	if(duration < ONE_FRAME)
		sleep (ONE_FRAME - duration)
	end
end

