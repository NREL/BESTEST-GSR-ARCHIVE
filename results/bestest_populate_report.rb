# This takes data from OpenStudio server csv file and populates a copy of the Standard 140 Results spreadsheets
# See steps below taken prior to running this script.

# Run OpenStudio server projects from "integration testing directory"
# The reporting measure in the project contains runner.registerValues objects that in turn get written into the results csv.
# In the future the runner.registerValue data will live in the OSW file with each datapoint.

# requires
require 'csv'
require 'fileutils'
require 'rubyXL' # install gem first
# gem documentation # http://www.rubydoc.info/gems/rubyXL/1.1.12/RubyXL/Cell
# https://github.com/weshatheleopard/rubyXL



# Load in CSV file
csv_file = 'bestest_os_server_output.csv'
csv_hash = {}
CSV.foreach(csv_file, :headers => true, :header_converters => :symbol, :converters => :all) do |row|
  short_name = row.fields[6].split(" ").first
  csv_hash[short_name] = Hash[row.headers[1..-1].zip(row.fields[1..-1])]
end
puts "CSV has #{csv_hash.size} entries."
puts "Hash keys are #{csv_hash.keys}" # keys made from column 6

# Copy Excel File
orig_results_5_2a = 'resources/RESULTS5-2A.xlsx'
copy_results_5_2a = 'RESULTS5-2A.xlsx'
puts "Making a copy of #{orig_results_5_2a}"
FileUtils.cp(orig_results_5_2a, copy_results_5_2a)

# Load Excel File
workbook = RubyXL::Parser.parse(copy_results_5_2a)
worksheet = workbook['YourData']
puts "Loading #{worksheet.sheet_name} Worksheet"

puts "Populating Annual Heating Loads"
(64..98).each do |i|
  target_case = worksheet.sheet_data[i][0].value
  worksheet.sheet_data[i][1].change_contents(csv_hash[target_case][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
end

puts "Populating Annual Cooling Loads"
(103..137).each do |i|
  target_case = worksheet.sheet_data[i][0].value
  worksheet.sheet_data[i][1].change_contents(csv_hash[target_case][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_cooling])
end

puts "Populating Annual Houlry Integrated Peak Heating Loads"
(145..179).each do |i|
  target_case = worksheet.sheet_data[i][0].value

  # get date and time from raw value
  raw_value = csv_hash[target_case][:bestest_building_thermal_envelope_and_fabric_load_reportspeak_heating_time_display_name]
  date = raw_value[0,6]
  time = raw_value[7,2].to_i

  # populate value date and time columns
  worksheet.sheet_data[i][1].change_contents(csv_hash[target_case][:bestest_building_thermal_envelope_and_fabric_load_reportspeak_heating_value])
  worksheet.sheet_data[i][2].change_contents(date)
  worksheet.sheet_data[i][3].change_contents(time)
end

puts "Populating Annual Houlry Integrated Peak Cooling Loads"
(198..232).each do |i|
  target_case = worksheet.sheet_data[i][0].value

  # get date and time from raw value
  raw_value = csv_hash[target_case][:bestest_building_thermal_envelope_and_fabric_load_reportspeak_cooling_time_display_name]
  date = raw_value[0,6]
  time = raw_value[7,2].to_i

  # populate value date and time columns
  worksheet.sheet_data[i][1].change_contents(csv_hash[target_case][:bestest_building_thermal_envelope_and_fabric_load_reportspeak_cooling_value])
  worksheet.sheet_data[i][2].change_contents(date)
  worksheet.sheet_data[i][3].change_contents(time)
end

# todo - add registerValue to csv for min, max, and average temps
=begin
puts "Populating FF Max Hourly Zone Temperature"
# this also includes case 960
(253..257).each do |i|
  target_case = worksheet.sheet_data[i][0].value

  # get date and time from raw value
  raw_value = csv_hash[target_case][:bestest_building_thermal_envelope_and_fabric_load_reportsmax_hourly_temp_time_display_name]
  date = raw_value[0,6]
  time = raw_value[7,2].to_i

  # populate value date and time columns
  worksheet.sheet_data[i][1].change_contents(csv_hash[target_case][:bestest_building_thermal_envelope_and_fabric_load_reportsmax_hourly_temp])
  worksheet.sheet_data[i][2].change_contents(date)
  worksheet.sheet_data[i][3].change_contents(time)
end

puts "Populating FF Min Hourly Zone Temperature"
# this also includes case 960
(262..266).each do |i|
  target_case = worksheet.sheet_data[i][0].value

  # get date and time from raw value
  raw_value = csv_hash[target_case][:bestest_building_thermal_envelope_and_fabric_load_reportsmin_hourly_temp_time_display_name]
  date = raw_value[0,6]
  time = raw_value[7,2].to_i

  # populate value date and time columns
  worksheet.sheet_data[i][1].change_contents(csv_hash[target_case][:bestest_building_thermal_envelope_and_fabric_load_reportsmin_hourly_temp])
  worksheet.sheet_data[i][2].change_contents(date)
  worksheet.sheet_data[i][3].change_contents(time)
end

puts "Populating FF Average Hourly Zone Temperature"
# this also includes case 960
(271..275).each do |i|
  target_case = worksheet.sheet_data[i][0].value

  # get date and time from raw value
  raw_value = csv_hash[target_case][:bestest_building_thermal_envelope_and_fabric_load_reportsavg_hourly_temp_time_display_name]
  date = raw_value[0,6]
  time = raw_value[7,2].to_i

  # populate value date and time columns
  worksheet.sheet_data[i][1].change_contents(csv_hash[target_case][:bestest_building_thermal_envelope_and_fabric_load_reportsavg_hourly_temp])
  worksheet.sheet_data[i][2].change_contents(date)
  worksheet.sheet_data[i][3].change_contents(time)
end
=end

# todo - Annual Incident Total Case 600 (293-294)

# todo - Unshaded Annual Transmitted Cases 920 and 900 (312-313)

# todo - Shaded Annual Transmitted Cases 930 and 910 (332-333)

puts "Populating Hourly Incident Solar Radiation Cloudy Day March 5th Case 600 - South"
array = csv_hash['600'][:bestest_building_thermal_envelope_and_fabric_load_reportssurf_out_inst_slr_rad_0305_zone_surface_south].split(",")
counter = 0
(348..371).each do |i|
  worksheet.sheet_data[i][1].change_contents(array[counter+2].to_f)
  counter += 1
end

# todo - finish up case 600 South and West March 5th and July 27th
=begin
puts "Populating Hourly Incident Solar Radiation Cloudy Day March 5th Case 600 - West"
array = csv_hash['600'][:bestest_building_thermal_envelope_and_fabric_load_reportssurf_out_inst_slr_rad_0305_zone_surface_west].split(",")
counter = 0
(388..411).each do |i|
  worksheet.sheet_data[i][1].change_contents(array[counter+2].to_f)
  counter += 1
end

puts "Populating Hourly Incident Solar Radiation Clear Day July 27th Case 600 - South"
array = csv_hash['600'][:bestest_building_thermal_envelope_and_fabric_load_reportssurf_out_inst_slr_rad_0727_zone_surface_south].split(",")
counter = 0
(388..411).each do |i|
  worksheet.sheet_data[i][1].change_contents(array[counter+2].to_f)
  counter += 1
end

puts "Populating Hourly Incident Solar Radiation Clear Dat July 27th Case 600 - West"
array = csv_hash['600'][:bestest_building_thermal_envelope_and_fabric_load_reportssurf_out_inst_slr_rad_0727_zone_surface_west].split(",")
counter = 0
(388..411).each do |i|
  worksheet.sheet_data[i][1].change_contents(array[counter+2].to_f)
  counter += 1
end
=end

# todo - make sure these hourly temps are being captured in registerValues
=begin
puts "Hourly FF Temperatures January 4th - Case 900FF"
array = csv_hash['900FF'][:bestest_building_thermal_envelope_and_fabric_load_reportstemp_0104].split(",")
counter = 0
(547..570).each do |i|
  worksheet.sheet_data[i][1].change_contents(array[counter+2].to_f)
  counter += 1
end

puts "Hourly FF Temperatures July 27 - Case 650FF"
array = csv_hash['650FF'][:bestest_building_thermal_envelope_and_fabric_load_reportstemp_0727].split(",")
counter = 0
(587..610).each do |i|
  worksheet.sheet_data[i][1].change_contents(array[counter+2].to_f)
  counter += 1
end

puts "Hourly FF Temperatures July 27 - Case 950FF"
array = csv_hash['950FF'][:bestest_building_thermal_envelope_and_fabric_load_reportstemp_0727].split(",")
counter = 0
(627..651).each do |i|
  worksheet.sheet_data[i][1].change_contents(array[counter+2].to_f)
  counter += 1
end
=end

puts "Populating Hourly Heating and Cooling Load 0104 - Case 600"
array = csv_hash['600'][:bestest_building_thermal_envelope_and_fabric_load_reportssens_htg_clg_0104].split(",")
counter = 0
(667..690).each do |i|
  worksheet.sheet_data[i][1].change_contents(array[counter+2].to_f)
  counter += 1
end

puts "Populating Hourly Heating and Cooling Load 0104 - Case 900"
array = csv_hash['900'][:bestest_building_thermal_envelope_and_fabric_load_reportssens_htg_clg_0104].split(",")
counter = 0
(707..730).each do |i|
  worksheet.sheet_data[i][1].change_contents(array[counter+2].to_f)
  counter += 1
end

puts "Hourly Annual Zone Temperature Bin Data - Case 900FF"
array = csv_hash['900FF'][:bestest_building_thermal_envelope_and_fabric_load_reportstemp_bins].split(",")
# bin array is just -20 to 70C. The spreadsheet looks for -50 to 98C. May need to extend array or make blanks 0.
counter = 0
(779..868).each do |i|
  worksheet.sheet_data[i][1].change_contents(array[counter+2].to_f)
  counter += 1
end

# Save Updated Excel File
puts "Saving #{copy_results_5_2a}"
workbook.write(copy_results_5_2a)