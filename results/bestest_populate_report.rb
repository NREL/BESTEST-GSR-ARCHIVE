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


# Save Updated Excel File
puts "Saving #{copy_results_5_2a}"
workbook.write(copy_results_5_2a)