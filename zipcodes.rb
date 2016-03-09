class ZipCodes
	def self.lookup(zip)
		load_zipcodes
		@@zip_to_location[zip]
	end

	def self.load_zipcodes
		if !defined?(@@zip_to_location)
			@@zip_to_location = {}
			CSV.read("./zipcodes.csv").each do |line|
				@@zip_to_location[line[0]] = [line[3].to_f, line[4].to_f]
			end
		end
	end
end