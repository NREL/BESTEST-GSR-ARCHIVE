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
  csv_hash[row.fields[6]] = Hash[row.headers[1..-1].zip(row.fields[1..-1])]
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

# todo - Popluate Annual Heating Loads
# to make easier pas in an array of cases or sort and filter keys, and do for each to change index values.
puts "Populating Annual Heating Loads"
worksheet.sheet_data[64][1].change_contents(csv_hash['600 - Base Case'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[65][1].change_contents(csv_hash['610 - South Shading'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[66][1].change_contents(csv_hash['620 - East/West Window Orientation'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[67][1].change_contents(csv_hash['630 - East/West Shading'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[68][1].change_contents(csv_hash['640 - Thermostat Setback'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[69][1].change_contents(csv_hash['650 - Night Ventilation'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[70][1].change_contents(csv_hash['900 - High-Mass Base Case'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[71][1].change_contents(csv_hash['910 - High-Mass South Shading'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[72][1].change_contents(csv_hash['920 - High-Mass East/West Window Orientation'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[73][1].change_contents(csv_hash['930 - High-Mass East/West Shading'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[74][1].change_contents(csv_hash['940 - High-Mass Thermostat Setback'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[75][1].change_contents(csv_hash['950 - High-Mass Night Ventilation'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[76][1].change_contents(csv_hash['960 - Sunspace'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[77][1].change_contents(csv_hash['195 - Solid Conduction Test'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[78][1].change_contents(csv_hash['200 - Surface Convection/Infrared Radiation'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[79][1].change_contents(csv_hash['210 - Interior Infrared Radiation'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])
worksheet.sheet_data[80][1].change_contents(csv_hash['215 - Exterior Infrared Radiation'][:bestest_building_thermal_envelope_and_fabric_load_reportsannual_heating])

# Save Updated Excel File
puts "Saving #{copy_results_5_2a}"
workbook.write(copy_results_5_2a)