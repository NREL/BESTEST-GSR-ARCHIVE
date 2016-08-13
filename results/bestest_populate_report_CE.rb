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

# todo - before I commit update all registerValues ot be unique (add table name and if needed 3a vs. 3b)

# Copy first Excel File
orig_results_5_3a = 'resources/RESULTS5-3A.xlsx'
copy_results_5_3a = 'RESULTS5-3A.xlsx'
puts "Making a copy of #{orig_results_5_3a}"
FileUtils.cp(orig_results_5_3a, copy_results_5_3a)

# Load Excel File
workbook = RubyXL::Parser.parse(copy_results_5_3a)
worksheet = workbook['YourData']
puts "Loading #{worksheet.sheet_name} Worksheet"

# make array for columns on table
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
  target_case = worksheet.sheet_data[i][0].value

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

# make array for columns on table
columns = []

columns << :bestest_ce_reportingann_sum_evap_coil_load_total
columns << :bestest_ce_reportingann_sum_evap_coil_load_sensible
columns << :bestest_ce_reportingann_sum_evap_coil_load_latent
columns << :bestest_ce_reportingann_mean_cop2
columns << :bestest_ce_reportingann_mean_idb
columns << :bestest_ce_reportingann_mean_zone_relative_humidity_ratio
columns << :bestest_ce_reportingann_mean_odb # CE300 only
columns << :bestest_ce_reportingann_mean_outdoor_humidity_ratio #CE300 only

# populate table on YourData
puts "Populating Annual Sums and Means Table"
(61..73).each do |i|
  target_case = worksheet.sheet_data[i][0].value
  puts "Adding row for #{target_case}"
  # loop through columns for each case
  columns.each_with_index do |column,j|
    worksheet.sheet_data[i][j+1].change_contents(csv_hash[target_case][column])
  end
end
(76..81).each do |i|
  target_case = worksheet.sheet_data[i][0].value
  puts "Adding row for #{target_case}"
  # loop through columns for each case
  columns.each_with_index do |column,j|
    worksheet.sheet_data[i][j+1].change_contents(csv_hash[target_case][column])
  end
end

# Fill in two special rows in table for CE500 and CE510 only
columns << :bestest_ce_reportingmay_sept_sum_clg_consumption_total
columns << :bestest_ce_reportingmay_sept_sum_clg_consumption_compressor
columns << :bestest_ce_reportingmay_sept_sum_clg_consumption_cond_fan
columns << :bestest_ce_reportingmay_sept_sum_clg_consumption_indoor_fan
columns << :bestest_ce_reportingmay_sept_sum_evap_coil_load_total
columns << :bestest_ce_reportingmay_sept_sum_evap_coil_load_sensible
columns << :bestest_ce_reportingmay_sept_sum_evap_coil_load_latent
columns << :bestest_ce_reportingmay_sept_mean_cop2
columns << :bestest_ce_reportingmay_sept_mean_idb
columns << :bestest_ce_reportingmay_sept_mean_zone_relative_humidity_ratio
# CE500 May-Sep
columns.each_with_index do |column,j|
  worksheet.sheet_data[74][j+1].change_contents(csv_hash["CE500"][column])
end
# CE510 May-Sep
columns.each_with_index do |column,j|
  worksheet.sheet_data[75][j+1].change_contents(csv_hash["CE510"][column])
end

# make array for columns on table
columns = []
columns << :bestest_ce_reportingenergy_consumption_comp_both_fans_wh
columns << :bestest_ce_reportingenergy_consumption_comp_both_fans_date
columns << :bestest_ce_reportingenergy_consumption_comp_both_fans_hr
columns << :bestest_ce_reportingevap_coil_load_sensible_wh
columns << :bestest_ce_reportingevap_coil_load_sensible_date
columns << :bestest_ce_reportingevap_coil_load_sensible_hr
columns << :bestest_ce_reportingevap_coil_load_latent_wh
columns << :bestest_ce_reportingevap_coil_load_latent_date
columns << :bestest_ce_reportingevap_coil_load_latent_hr
columns << :bestest_ce_reportingevap_coil_load_sensible_and_latent_wh
columns << :bestest_ce_reportingevap_coil_load_sensible_and_latent_date
columns << :bestest_ce_reportingevap_coil_load_sensible_and_latent_hr
columns << :bestest_ce_reportingweather_odb_c # CE300 only
columns << :bestest_ce_reportingweather_odb_date # CE300 only
columns << :bestest_ce_reportingweather_odb_hr # CE300 only
columns << :bestest_ce_reportingweather_outdoor_humidity_ratio_c # CE300 only
columns << :bestest_ce_reportingweather_outdoor_humidity_ratio_date # CE300 only
columns << :bestest_ce_reportingweather_outdoor_humidity_ratio_hr # CE300 only

# populate table on YourData
puts "Annual Hourly Integrated Maxima Consumptions and Loads Table"
(61..80).each do |i|
  target_case = worksheet.sheet_data[i][15].value
  puts "Adding row for #{target_case}"
  # loop through columns for each case
  columns.each_with_index do |column,j|
    worksheet.sheet_data[i][j+16].change_contents(csv_hash[target_case][column])
  end
end

# make array for columns on table
columns = []
columns << :bestest_ce_reportingcop2_max_cop2
columns << :bestest_ce_reportingcop2_max_date
columns << :bestest_ce_reportingcop2_max_hr
columns << :bestest_ce_reportingcop2_min_cop2
columns << :bestest_ce_reportingcop2_min_date
columns << :bestest_ce_reportingcop2_min_hr
columns << :bestest_ce_reportingidb_max_idb
columns << :bestest_ce_reportingidb_max_date
columns << :bestest_ce_reportingidb_max_hr
columns << :bestest_ce_reportingidb_min_idb
columns << :bestest_ce_reportingidb_min_date
columns << :bestest_ce_reportingidb_min_hr
columns << :bestest_ce_reportinghr_max_humidity_ratio
columns << :bestest_ce_reportinghr_max_date
columns << :bestest_ce_reportinghr_max_hr
columns << :bestest_ce_reportinghr_min_humidity_ratio
columns << :bestest_ce_reportinghr_min_date
columns << :bestest_ce_reportinghr_min_hr
columns << :bestest_ce_reportingrh_max_relative_humidity
columns << :bestest_ce_reportingrh_max_date
columns << :bestest_ce_reportingrh_max_hr
columns << :bestest_ce_reportingrh_min_relative_humidity
columns << :bestest_ce_reportingrh_min_date
columns << :bestest_ce_reportingrh_min_hr

# populate table on YourData
puts "Annual Hourly Integrated Maxima - COP2 and Zone Table"
(88..107).each do |i|
  target_case = worksheet.sheet_data[i][15].value
  puts "Adding row for #{target_case}"
  # loop through columns for each case
  columns.each_with_index do |column,j|
    worksheet.sheet_data[i][j+16].change_contents(csv_hash[target_case][column])
  end
end

# pouplate table
# todo - each column is registerValue with string that can be converted to array with 24 items
columns = []
columns << :bestest_ce_reporting0628_hourly_energy_consumpton_compressor
columns << :bestest_ce_reporting0628_hourly_energy_consumpton_cond_fan
columns << :bestest_ce_reporting0628_hourly_evaporator_coil_load_total
columns << :bestest_ce_reporting0628_hourly_evaporator_coil_load_sensible
columns << :bestest_ce_reporting0628_hourly_evaporator_coil_load_latent
columns << :bestest_ce_reporting0628_hourly_zone_humidity_ratio
columns << :bestest_ce_reporting0628_hourly_cop2
columns << :bestest_ce_reporting0628_hourly_odb
columns << :bestest_ce_reporting0628_hourly_edb
columns << :bestest_ce_reporting0628_hourly_ewb
columns << :bestest_ce_reporting0628_hourly_outdoor_humidity_ratio

puts "Case 300 June 28th Hourly Table"
columns.each_with_index do |column,j|
  array = csv_hash['CE300'][column]
  array.each_with_index do |hourly_value,i|
    worksheet.sheet_data[i+88][j+1].change_contents(hourly_value)
  end
end

# pouplate table
puts "Case 500 and 530 Average Daily Outputs"

# make array for columns on table
columns = []
columns << :bestest_ce_reporting0430_day_energy_consumption_total
columns << :bestest_ce_reporting0430_day_energy_consumption_compressor
columns << :bestest_ce_reporting0430_day_energy_consumption_supply_fan
columns << :bestest_ce_reporting0430_day_energy_consumption_condenser_fan
columns << :bestest_ce_reporting0430_day_evaporator_coil_load_total
columns << :bestest_ce_reporting0430_day_evaporator_coil_load_sensible
columns << :bestest_ce_reporting0430_day_evaporator_coil_load_latent
columns << :bestest_ce_reporting0430_day_zone_humidity_ratio
columns << :bestest_ce_reporting0430_day_cop2
columns << :bestest_ce_reporting0430_day_odb
columns << :bestest_ce_reporting0430_day_edb

columns.each_with_index do |column,j|
  worksheet.sheet_data[119][j+1].change_contents(csv_hash['CE500'][column])
  worksheet.sheet_data[128][j+1].change_contents(csv_hash['CE530'][column])
end

# make array for columns on table
columns = []
columns << :bestest_ce_reporting0430_day_energy_consumption_total
columns << :bestest_ce_reporting0430_day_energy_consumption_compressor
columns << :bestest_ce_reporting0430_day_energy_consumption_supply_fan
columns << :bestest_ce_reporting0430_day_energy_consumption_condenser_fan
columns << :bestest_ce_reporting0430_day_evaporator_coil_load_total
columns << :bestest_ce_reporting0430_day_evaporator_coil_load_sensible
columns << :bestest_ce_reporting0430_day_evaporator_coil_load_latent
columns << :bestest_ce_reporting0430_day_zone_humidity_ratio
columns << :bestest_ce_reporting0430_day_cop2
columns << :bestest_ce_reporting0430_day_odb
columns << :bestest_ce_reporting0430_day_edb

columns.each_with_index do |column,j|
  worksheet.sheet_data[120][j+1].change_contents(csv_hash['CE500'][column])
  worksheet.sheet_data[129][j+1].change_contents(csv_hash['CE530'][column])
end

# todo - pouplate table
puts "Case 530 Average Daily Outputs"

# Save Updated Excel File
puts "Saving #{copy_results_5_3b}"
workbook.write(copy_results_5_3b)