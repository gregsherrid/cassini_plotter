require 'csv'
require 'mini_magick'

PIN_SCALE = 15

input_location_file = ARGV[0]
raise "Please provide a csv file of ZIP codes" if input_location_file.nil?
output_image_file = ARGV[1] || "./outputs/output-#{Time.now.to_i}.png"

def main(map_template_file, output_file)
	loc_pairs = us_zip_codes_to_lat_longs(map_template_file)
	output_map(loc_pairs, output_file)
end

def output_map(loc_pairs, output_image_file)
	map_base = MiniMagick::Image.new("./templates/mainland-us-mercator-smaller-green.png")
	map_width = map_base.width
	map_height = map_base.height

	pin = MiniMagick::Image.new("./images/blue-mark.png")
	pin.resize "#{PIN_SCALE}x#{PIN_SCALE}"

	pin_width = pin.width
	pin_height = pin.height


	result = map_base

	loc_pairs.each_with_index do |pair, i|
		x = scaled_longitude(pair[1], map_width) - pin_width / 2
		y = scaled_latitude(pair[0], map_height) - pin_height
		puts "#{i}:   #{x} x #{y}"

		result = result.composite(pin) do |c|
			c.compose "Over"
			c.geometry "+#{x}+#{y}"
		end
	end
	result.write output_image_file
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


def us_zip_codes_to_lat_longs(file)
	zipcode_to_location = {}
	CSV.read("./zipcodes.csv").each do |line|
		zipcode_to_location[line[0]] = [line[3].to_f, line[4].to_f]
	end
	locations = []
	CSV.read(file).each do |a|
		locations << zipcode_to_location[a[0]]
	end

	locations.compact
end

main(input_location_file, output_image_file)

