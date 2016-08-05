# This takes data from OpenStudio server csv file and populates a copy of the Standard 140 Results spreadsheets
# See steps below taken prior to running this script.

# Run OpenStudio server projects from "integration testing directory"
# The reporting measure in the project contains runner.registerValues objects that in turn get written into the results csv.
# In the future the runner.registerValue data will live in the OSW file with each datapoint.
# run scrpint from directory script is in "Results"

# requires
require 'csv'
require 'fileutils'
require 'rubyXL' # install gem first
# gem documentation # http://www.rubydoc.info/gems/rubyXL/1.1.12/RubyXL/Cell
# https://github.com/weshatheleopard/rubyXL



# Load in CSV file
csv_file = 'bestest_os_server_output_ce.csv'
csv_hash = {}
CSV.foreach(csv_file, :headers => true, :header_converters => :symbol, :converters => :all) do |row|
  short_name = row.fields[6].split(" ").first
  csv_hash[short_name] = Hash[row.headers[1..-1].zip(row.fields[1..-1])]
end
puts "CSV has #{csv_hash.size} entries."
puts "Hash keys are #{csv_hash.keys}" # keys made from column 6



# Copy first Excel File
orig_results_5_3a = 'resources/RESULTS5-3A.xlsx'
copy_results_5_3a = 'RESULTS5-3A.xlsx'
puts "Making a copy of #{orig_results_5_3a}"
FileUtils.cp(orig_results_5_3a, copy_results_5_3a)

# Load Excel File
workbook = RubyXL::Parser.parse(copy_results_5_3a)
worksheet = workbook['YourData']
puts "Loading #{worksheet.sheet_name} Worksheet"

# todo - update content
# make array for columns on table
# convert to symbolic for use below
columns = []
columns << :bestest_ce_reportingclg_energy_consumption_total
columns << :bestest_ce_reportingclg_energy_consumption_compressor
columns << :bestest_ce_reportingclg_energy_consumption_supply_fan
columns << :bestest_ce_reportingclg_energy_consumption_condenser_fan
columns << :bestest_ce_reportingevaporator_coil_load_total
columns << :bestest_ce_reportingevaporator_coil_load_sensible
columns << :bestest_ce_reportingevaporator_coil_load_latent
columns << :bestest_ce_reportingzone_load_total
columns << :bestest_ce_reportingzone_load_sensible
columns << :bestest_ce_reportingzone_load_latent
columns << :bestest_ce_reportingfeb_mean_cop
columns << :bestest_ce_reportingfeb_mean_idb
columns << :bestest_ce_reportingfeb_mean_humidity_ratio
columns << :bestest_ce_reportingfeb_max_cop
columns << :bestest_ce_reportingfeb_max_idb
columns << :bestest_ce_reportingfeb_max_humidity_ratio
columns << :bestest_ce_reportingfeb_min_cop
columns << :bestest_ce_reportingfeb_min_idb
columns << :bestest_ce_reportingfeb_min_humidity_ratio

# populate table on YourData
puts "Populating main table for 5-3A"
(24..37).each do |i|
  target_case = worksheet.sheet_data[i][0].value.to_s.split(':').first

  puts "Adding row for #{target_case}"
  # loop through columns for each case
  columns.each_with_index do |column,j|
    worksheet.sheet_data[i][j+1].change_contents(csv_hash[target_case][column])
  end

end

# Save Updated Excel File
puts "Saving #{copy_results_5_3a}"
workbook.write(copy_results_5_3a)



# Copy second Excel File
orig_results_5_3b = 'resources/RESULTS5-3B.xlsx'
copy_results_5_3b = 'RESULTS5-3B.xlsx'
puts "Making a copy of #{orig_results_5_3b}"
FileUtils.cp(orig_results_5_3b, copy_results_5_3b)

# Load Excel File
workbook = RubyXL::Parser.parse(copy_results_5_3b)
worksheet = workbook['YourData']
puts "Loading #{worksheet.sheet_name} Worksheet"

# todo - update content

# Save Updated Excel File
puts "Saving #{copy_results_5_3b}"
workbook.write(copy_results_5_3b)