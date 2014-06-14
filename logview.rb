#!/usr/bin/env ruby

#
# Background log message viewer 
# Author		hawstan (Stanley Hawkeye)
# Date		2014-06-15
# Version		0.1
# License		GPLv2
#

require 'sdl'

logfileName = ARGV[0]

if(logfileName == nil)
	$stderr.puts "Argument 1 shall be the name of a log file"
	exit
end

#TODO dynamic dimensions
WIDTH = 1000
HEIGHT = 500

ONE_FRAME = 0.1


SDL.init( SDL::INIT_VIDEO )

screen = SDL::Screen.open(WIDTH, HEIGHT, 16, SDL::SWSURFACE)
SDL::WM::set_caption($0,$0)

SDL::TTF.init

#TODO dynamic font
font = SDL::TTF.open('/usr/share/fonts/liberation/LiberationMono-Regular.ttf', 10)
font.style = SDL::TTF::STYLE_NORMAL

numLines = HEIGHT / font.height

file = File.new(logfileName, "r")

lines = []

loop do
	startTime = Time.now

	while event = SDL::Event2.poll
		case event
			when SDL::Event2::Quit
				font.close
				file.close
				exit
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

		# clear the screen with black
		screen.fillRect(0, 0, WIDTH, HEIGHT, 0x000000)

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

