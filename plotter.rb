require 'mini_magick'

class Plotter
	def initialize(template_path = DEFAULT_TEMPLATE_PATH)
		map_base = MiniMagick::Image.open(template_path)
		@working_map = map_base

		@map_width = map_base.width
		@map_height = map_base.height
	end

	def init_pin(scale = DEFAULT_PIN_SCALE, pin_path = DEFAULT_PIN_PATH)
		@pin = MiniMagick::Image.open(pin_path)
		@pin.resize "#{ scale }x#{ scale }"

		@pin_width = @pin.width
		@pin_height = @pin.height
	end

	def init_circle(max_radius = DEFAULT_CIRCLE_MAX_RADIUS, circle_path = DEFAULT_CIRCLE_PATH)
		@circle = MiniMagick::Image.open(circle_path)
		@max_circle_radius = max_radius
	end

	def place_pin(location, noisy_index = nil)
		x = scaled_longitude(location[1], @map_width) - @pin_width / 2
		y = scaled_latitude(location[0], @map_height) - @pin_height

		puts "#{noisy_index}:   #{x} x #{y}" if noisy_index
		
		@working_map = @working_map.composite(@pin) do |c|
			c.compose "Over"
			c.geometry "+#{x}+#{y}"
		end
	end

	# Size is relative to max_radius, (0..1)
	def place_circle(location, size, noisy_index = nil)
		radius = @max_circle_radius * size

		# Correctly size circle
		@circle.resize "#{ radius * 2 }x#{ radius * 2 }"

		x = scaled_longitude(location[1], @map_width) - radius
		y = scaled_latitude(location[0], @map_height) - radius

		puts "#{noisy_index}:   #{x} x #{y}" if noisy_index
		
		@working_map = @working_map.composite(@circle) do |c|
			c.compose "Over"
			c.geometry "+#{x}+#{y}"
		end
	end

	def scaled_latitude(lat, scale)
		south = 24.396308
		north = 49.384358

		scale - (((lat - south) / (north - south)) * scale).floor
	end

	def scaled_longitude(long, scale)
		west = -124.848974
		east = -66.885444
		scale - (((long - east) / (west - east)) * scale).floor
	end

	def save(output_path)
		@working_map.write output_path
	end

	DEFAULT_TEMPLATE_PATH = "./templates/mainland-us-mercator-smaller-green.png"

	DEFAULT_PIN_SCALE = 15
	DEFAULT_PIN_PATH = "./images/blue-mark.png"

	DEFAULT_CIRCLE_MAX_RADIUS = 20
	DEFAULT_CIRCLE_PATH = './images/blue-transparent-circle.png'

end