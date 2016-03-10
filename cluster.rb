require 'csv'
require 'set'
require './zipcodes.rb'
require './plotter.rb'

# Max cluster size, in meters
CLUSTER_RADIUS = 80000
DELIMITER = "\t"
USE_ITEM_WEIGHT = true
MAX_CLUSTERS = 80

input_location_file = ARGV[0]
raise "Please provide a csv file of ZIP codes" if input_location_file.nil?

output_time = Time.now.to_i

output_image_file = ARGV[1] || "./outputs/cluster-output-#{ output_time }.png"
output_csv_file = ARGV[2] || "./outputs/cluster-output-#{ output_time }.csv"
output_txt_file = ARGV[3] || "./outputs/cluster-output-#{ output_time }.txt"

def main_cluster(input_file, output_map_file, output_cluser_zips_file, output_cluster_text_file)
	items = []
	zips = Set.new
	CSV.foreach(input_file, headers: true, col_sep: DELIMITER) do |row|
		location = ZipCodes.lookup(row["ZIP"])
		if location
			items << row.to_hash
			zips << row["ZIP"]
		end
	end

	# Build a matrix to lookup any pair of zips
	matrix = {}
	zips.each do |zip1|
		zips.each do |zip2|
			dist = get_zip_distance(zip1, zip2)
			key = "#{zip1}x#{zip2}"
			matrix[key] = dist
		end
	end

	clusters = []
	cluster_centers = []

	# Take out the largest cluster one cluster at a time
	while items.any? && clusters.length < MAX_CLUSTERS

		# Bulid a hash of zips to the cluster 'size' (by weight or count)
		zip_to_cluster_size = {}
		zips.each do |zip1|
			next if zip_to_cluster_size[zip1]
			zip_to_cluster_size[zip1] = 0

			# Find remaining items within the cluster radius
			items.each do |item|
				dist = get_zip_distance(zip1, item["ZIP"])
				if dist <= CLUSTER_RADIUS
					inc = USE_ITEM_WEIGHT ? item["Weight"].to_i : 1
					zip_to_cluster_size[zip1] += inc
				end
			end
		end

		# Pick the largest zip, take the cluster around it, and remove it from items
		center_zip = zip_to_cluster_size.to_a.max_by { |pair| pair[1] }[0]

		cluster = items.select do |item|
			dist = get_zip_distance(center_zip, item["ZIP"])
			dist <= CLUSTER_RADIUS
		end

		clusters << cluster
		cluster_centers << center_zip
		items -= cluster

		weight = sum_cluster_weight(cluster)
		puts "#{ items.length } Left : #{ weight } & #{ cluster.length }"
	end

	max_cluster_weight = clusters.map { |c| sum_cluster_weight(c) }.max
	max_cluster_count = clusters.map(&:length).max

	plotter = Plotter.new
	plotter.init_circle

	zips_lines = []
	item_lines = []

	clusters.length.times do |i|
		cluster = clusters[i]
		center_zip = cluster_centers[i]

		zips_lines << cluster.map { |h| h["ZIP"] }.uniq.join("\t")

		location = ZipCodes.lookup(center_zip)

		# Calculate the size of the cluster relative to the max
		size = if USE_ITEM_WEIGHT			
			sum_cluster_weight(cluster).to_f / max_cluster_weight
		else
			cluster.length / max_cluster_count
		end

		item_lines += cluster.map { |item| item.values.join("\t") }
		item_lines << ""

		plotter.place_circle(location, size, i)
		puts "#{ cluster.first["zip"] } - #{ size }"
	end

	File.open(output_cluser_zips_file, 'w') { |file| file.write(zips_lines.join("\n")) }
	File.open(output_cluster_text_file, 'w') { |file| file.write(item_lines.join("\n")) }
	plotter.save(output_map_file)
end

def sum_cluster_weight(cluster)
	cluster.inject(0) { |sum, item| sum + item["Weight"].to_i }
end

@cached_zips = {}
def get_zip_distance(zip1, zip2)
	key = "#{ zip1 }x#{ zip2 }"
	@cached_zips[key] ||= get_lat_long_distance(ZipCodes.lookup(zip1), ZipCodes.lookup(zip2))
end

# Thanks @Oto Brglez http://stackoverflow.com/questions/12966638/how-to-calculate-the-distance-between-two-gps-coordinates-without-using-google-m
# Takes inputs: ([lat1, long1], [lat2, long2])
def get_lat_long_distance(loc1, loc2)
	rad_per_deg = Math::PI/180  # PI / 180
	rkm = 6371                  # Earth radius in kilometers
	rm = rkm * 1000             # Radius in meters

	dlat_rad = (loc2[0]-loc1[0]) * rad_per_deg  # Delta, converted to rad
	dlon_rad = (loc2[1]-loc1[1]) * rad_per_deg

	lat1_rad, lon1_rad = loc1.map {|i| i * rad_per_deg }
	lat2_rad, lon2_rad = loc2.map {|i| i * rad_per_deg }

	a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
	c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

	rm * c # Delta in meters
end

main_cluster(input_location_file, output_image_file, output_csv_file, output_txt_file)
