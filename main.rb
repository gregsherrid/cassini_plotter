require 'csv'
require './zipcodes.rb'
require './plotter.rb'

input_location_file = ARGV[0]
raise "Please provide a csv file of ZIP codes" if input_location_file.nil?
output_image_file = ARGV[1] || "./outputs/output-#{Time.now.to_i}.png"

def main(zips_file, output_file)
	loc_pairs = us_zip_codes_to_lat_longs(zips_file)
	output_map(loc_pairs, output_file)
end

def output_map(loc_pairs, output_image_file)
	plotter = Plotter.new
	plotter.init_pin

	loc_pairs.each_with_index do |location, i|
		plotter.place_pin(location, i)
	end

	plotter.save(output_image_file)
end

def us_zip_codes_to_lat_longs(file)
	locations = []
	CSV.read(file).each do |a|
		locations << ZipCodes.lookup(a[0])
	end

	locations.compact
end

main(input_location_file, output_image_file)

