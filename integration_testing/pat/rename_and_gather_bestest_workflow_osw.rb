require 'fileutils'
require 'openstudio'

# This script is used to gather osw files from temp_data in live PAT project
# Use case is to run OSW files with CLI in the future without having to launch PAT

# loop through resoruce files
results_directories = Dir.glob("PAT_BESTEST_Manual/temp_data/analysis_8c246d43-a6a6-44a4-85ce-f8c06a66df3e/*")
results_directories.each do |results_directory|

	next if not results_directory.include?("data_point_")

	# load the test model
	translator = OpenStudio::OSVersion::VersionTranslator.new
	path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{results_directory}/in.osm")
	model = translator.loadModel(path)
	model = model.get

  # get and shorten building name
  building_name = model.getBuilding.name.to_s
  dash_index = building_name.index('-')
	if not dash_index.nil?
		short_name = building_name[0,dash_index - 1]
  else
    short_name = building_name
  end

	# copy and rename zip file
	orig_osw = "#{File.dirname(__FILE__)}/#{results_directory}/data_point.osw"
	copy_osw = "bestest_osws/#{short_name}/data_point.osw"
	puts "Creating #{short_name}/data_point.osw"
	directory_name = "bestest_osws/#{short_name}"
	Dir.mkdir(directory_name) unless File.exists?(directory_name)
	FileUtils.cp(orig_osw, copy_osw)

end
