# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'

#start the measure
class BESTESTCEReporting < OpenStudio::Ruleset::ReportingUserScript

  # human readable name
  def name
    return "BESTEST CE Reporting"
  end
  # human readable description
  def description
    return "This doesn't generate a user HTML file with any meaningful content. It is here to create runner.RegisterValue objects that will be post processed downstream."
  end
  # human readable description of modeling approach
  def modeler_description
    return "The CSV project for the analysis will be downloaded from the server and then a script will run to pull data into Local Excel File."
  end
  # define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # this measure does not require any user arguments, return an empty list

    return args
  end 
  
  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)
    
    result = OpenStudio::IdfObjectVector.new
    
    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(), user_arguments)
      return result
    end
    
    return result
  end
  
  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    # put data into the local variable 'output', all local variables are available for erb to use when configuring the input html file

    output =  "Measure Name = " << name << "<br>"
    output << "Building Name = " << model.getBuilding.name.get << "<br>"                       # optional variable
    output << "Floor Area = " << model.getBuilding.floorArea.to_s << "<br>"                   # double variable
    output << "Floor to Floor Height = " << model.getBuilding.nominalFloortoFloorHeight.to_s << " (m)<br>" # double variable
    output << "Net Site Energy = " << sqlFile.netSiteEnergy.to_s << " (GJ)<br>" # double variable

    web_asset_path = OpenStudio.getSharedResourcesPath() / OpenStudio::Path.new("web_assets")

    # read in template
    html_in_path = "#{File.dirname(__FILE__)}/resources/report.html.in"
    if File.exist?(html_in_path)
        html_in_path = html_in_path
    else
        html_in_path = "#{File.dirname(__FILE__)}/report.html.in"
    end
    html_in = ""
    File.open(html_in_path, 'r') do |file|
      html_in = file.read
    end

    # get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sqlFile.availableEnvPeriods.each do |env_pd|
      env_type = sqlFile.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          ann_env_pd = env_pd
          break
        end
      end
    end

    # only try to get the annual timeseries if an annual simulation was run
    if ann_env_pd

      # get desired variable
      key_value =  "Environment"
      time_step = "Hourly" # "Zone Timestep", "Hourly", "HVAC System Timestep"
      variable_name = "Site Outdoor Air Drybulb Temperature"
      output_timeseries = sqlFile.timeSeries(ann_env_pd, time_step, variable_name, key_value) # key value would go at the end if we used it.
      
      if output_timeseries.empty?
        runner.registerWarning("Timeseries not found.")
      else
        runner.registerInfo("Found timeseries.")
      end
    else
      runner.registerWarning("No annual environment period found.")
    end
    
    # configure template with variable values
    renderer = ERB.new(html_in)
    html_out = renderer.result(binding)
    
    # write html file
    html_out_path = "./report.html"
    File.open(html_out_path, 'w') do |file|
      file << html_out
      # make sure data is written to the disk one way or the other
      begin
        file.fsync
      rescue
        file.flush
      end
    end

    # this is in CE and Envelope, move to shared resource
    def process_output_timeseries (sqlFile, runner, ann_env_pd, time_step, variable_name, key_value)

      output_timeseries = sqlFile.timeSeries(ann_env_pd, time_step, variable_name, key_value)
      if output_timeseries.empty?
        runner.registerWarning("Timeseries not found for #{variable_name}.")
        return false
      else
        runner.registerInfo("Found timeseries for #{variable_name}.")
        output_values = output_timeseries.get.values
        output_times = output_timeseries.get.dateTimes
        array = []
        sum = 0.0
        min = nil
        min_date_time = nil
        max = nil
        max_date_time = nil

        for i in 0..(output_values.size - 1)

          # using this to get average
          array << output_values[i]
          sum += output_values[i]

          # code for min and max
          if min.nil? || output_values[i] < min
            min = output_values[i]
            min_date_time = output_times[i]
          end
          if max.nil? || output_values[i] > max
            max = output_values[i]
            max_date_time = output_times[i]
          end

        end
        return {:array => array, :sum => sum, :avg => sum/array.size.to_f, :min => min, :max => max, :min_date_time => min_date_time, :max_date_time => max_date_time}
      end

    end

    def date_time_parse(date_time)

      array = []

      month = date_time.date.monthOfYear.value
      day_of_month = date_time.date.dayOfMonth.to_s
      hour = date_time.time.hours

      # map month integer to short name
      case month
        when 1
          month = "Jan"
        when 2
          month = "Feb"
        when 3
          month = "Mar"
        when 4
          month = "Apr"
        when 5
          month = "May"
        when 6
          month = "Jun"
        when 7
          month = "Jul"
        when 8
          month = "Aug"
        when 9
          month = "Sep"
        when 10
          month = "Oct"
        when 11
          month = "Nov"
        when 12
          month = "Dec"
      end

      array << "#{day_of_month}-#{month}"
      array << hour

      return array

    end

    # add runner.registerValues for bestest reporting 5-3A
    if model.getBuilding.name.to_s.include? "CE1" or model.getBuilding.name.to_s.include? "CE2"

      # get clg_energy_consumption_total
      key_value =  "BESTEST CE AIR LOOP"
      variable_name = "Air System Electric Energy"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      total_cooling_energy_consumption_j = timeseries_hash
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'J','kWh').get
      runner.registerValue('clg_energy_consumption_total',value_kwh)
      # get clg_energy_consumption_compressor
      variable_name = "Air System DX Cooling Coil Electric Energy"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'J','kWh').get
      runner.registerValue('clg_energy_consumption_compressor',value_kwh)
      # get clg_energy_consumption_supply_fan
      variable_name = "Air System Fan Electric Energy"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'J','kWh').get
      runner.registerValue('clg_energy_consumption_supply_fan',value_kwh)
      # todo - can I get d directly or does d = a - b - c
      runner.registerValue('clg_energy_consumption_condenser_fan','tbd')

      # get evaporator_coil_load_total
      key_value =  "COIL COOLING DX SINGLE SPEED 1"
        variable_name = "Cooling Coil Total Cooling Rate"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'Wh','kWh').get
      runner.registerValue('evaporator_coil_load_total',value_kwh)
      # get evaporator_coil_load_sensible
      variable_name = "Cooling Coil Sensible Cooling Rate"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'Wh','kWh').get
      runner.registerValue('evaporator_coil_load_sensible',value_kwh)
      # get evaporator_coil_load_latent
      variable_name = "Cooling Coil Latent Cooling Rate"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'Wh','kWh').get
      runner.registerValue('evaporator_coil_load_latent',value_kwh)

      # get zone_load_total
      key_value =  "AIR LOOP HVAC UNITARY SYSTEM 1"
      variable_name = "Unitary System Total Cooling Rate"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      net_refrigeration_effect_w = timeseries_hash
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'Wh','kWh').get
      runner.registerValue('zone_load_total',value_kwh)
      # get zone_load_sensible
      variable_name = "Unitary System Sensible Cooling Rate"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'Wh','kWh').get
      runner.registerValue('zone_load_sensible',value_kwh)
      # get zone_load_latent
      variable_name = "Unitary System Latent Cooling Rate"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'Wh','kWh').get
      runner.registerValue('zone_load_latent',value_kwh)

      # get feb_cop
      mean_cop = net_refrigeration_effect_w[:avg] / (total_cooling_energy_consumption_j[:avg]/3600.0) # W = J/s
      runner.registerValue('feb_mean_cop',mean_cop)
      cop_array = []
      696.times.each do |i|
        cop_array << net_refrigeration_effect_w[:array][i]/(total_cooling_energy_consumption_j[:array][i]/3600.0) # W = J/s
      end
      runner.registerValue('feb_max_cop',cop_array.max)
      runner.registerValue('feb_min_cop',cop_array.min)
      # get feb_idb
      key_value =  "ZONE ONE"
      variable_name = "Zone Mean Air Temperature"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      runner.registerValue('feb_mean_idb',timeseries_hash[:avg])
      runner.registerValue('feb_max_idb',timeseries_hash[:max])
      runner.registerValue('feb_min_idb',timeseries_hash[:min])
      # get feb_humidity_ratio
      key_value =  "ZONE ONE"
      variable_name = "Zone Mean Air Humidity Ratio"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      runner.registerValue('feb_mean_humidity_ratio',timeseries_hash[:avg])
      runner.registerValue('feb_max_humidity_ratio',timeseries_hash[:max])
      runner.registerValue('feb_min_humidity_ratio',timeseries_hash[:min])

    else

      # todo - add runner.registerValues for bestest reporting 5-3B (replace tbd with real values)

      # Annual Sums and Means Table

      # get clg_energy_consumption_total
      key_value =  "BESTEST CE AIR LOOP"
      variable_name = "Air System Electric Energy"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      total_cooling_energy_consumption_j = timeseries_hash
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'J','kWh').get
      runner.registerValue('ann_sum_clg_energy_consumption_total',value_kwh)
      # get clg_energy_consumption_compressor
      variable_name = "Air System DX Cooling Coil Electric Energy"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'J','kWh').get
      runner.registerValue('ann_sum_clg_energy_consumption_compressor',value_kwh)
      # get clg_energy_consumption_supply_fan
      variable_name = "Air System Fan Electric Energy"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'J','kWh').get
      runner.registerValue('ann_sum_clg_energy_consumption_supply_fan',value_kwh)
      # todo - can I get d directly or does d = a - b - c
      runner.registerValue('ann_sum_clg_energy_consumption_condenser_fan','tbd')
      # get evaporator_coil_load_total
      key_value =  "COIL COOLING DX SINGLE SPEED 1"
      variable_name = "Cooling Coil Total Cooling Rate"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'Wh','kWh').get
      runner.registerValue('ann_sum_evap_coil_load_total',value_kwh)
      # get evaporator_coil_load_sensible
      variable_name = "Cooling Coil Sensible Cooling Rate"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'Wh','kWh').get
      runner.registerValue('ann_sum_evap_coil_load_sensible',value_kwh)
      # get evaporator_coil_load_latent
      variable_name = "Cooling Coil Latent Cooling Rate"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_kwh = OpenStudio.convert(timeseries_hash[:sum],'Wh','kWh').get
      runner.registerValue('ann_sum_evap_coil_load_latent',value_kwh)
      # get zone_load_total (for net_refrigeration_effect_w)
      key_value =  "AIR LOOP HVAC UNITARY SYSTEM 1"
      variable_name = "Unitary System Total Cooling Rate"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      net_refrigeration_effect_w = timeseries_hash
      # get cop
      mean_cop = net_refrigeration_effect_w[:avg] / (total_cooling_energy_consumption_j[:avg]/3600.0) # W = J/s
      runner.registerValue('ann_mean_cop2',mean_cop)
      # get idb
      key_value =  "ZONE ONE"
      variable_name = "Zone Mean Air Temperature"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      runner.registerValue('ann_mean_idb',timeseries_hash[:avg])
      # get humidity_ratio
      variable_name = "Zone Mean Air Humidity Ratio"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      runner.registerValue('ann_mean_zone_humidity_ratio',timeseries_hash[:avg])
      # get relative_humidity
      variable_name = "Zone Air Relative Humidity"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      runner.registerValue('ann_mean_zone_relative_humidity',timeseries_hash[:avg])
      # get site avg odb
      key_value =  "Environment"
      variable_name = "Site Outdoor Air Drybulb Temperature"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      runner.registerValue('ann_mean_odb',timeseries_hash[:avg])
      # get site avg humidity ratio
      variable_name = "Site Outdoor Air Humidity Ratio"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      runner.registerValue('ann_mean_outdoor_humidity_ratio',timeseries_hash[:avg])

      runner.registerValue('may_sept_sum_clg_consumption_total','tbd')
      runner.registerValue('may_sept_sum_clg_consumption_compressor','tbd')
      runner.registerValue('may_sept_sum_clg_consumption_cond_fan','tbd')
      runner.registerValue('may_sept_sum_clg_consumption_indoor_fan','tbd')
      runner.registerValue('may_sept_sum_evap_coil_load_total','tbd')
      runner.registerValue('may_sept_sum_evap_coil_load_sensible','tbd')
      runner.registerValue('may_sept_sum_evap_coil_load_latent','tbd')
      runner.registerValue('may_sept_mean_cop2','tbd')
      runner.registerValue('may_sept_mean_idb','tbd')
      runner.registerValue('may_sept_mean_zone_humidity_ratio','tbd')
      runner.registerValue('may_sept_mean_zone_relative_humidity','tbd')

      # Annual Hourly Integrated Maxima Consumptions and Loads Table

      # get supply_fan
      key_value =  "BESTEST CE AIR LOOP"
      variable_name = "Air System Fan Electric Energy"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_wh = OpenStudio.convert(timeseries_hash[:max],'J','Wh').get
      runner.registerValue('energy_consumption_comp_both_fans_wh',value_wh)
      runner.registerValue('energy_consumption_comp_both_fans_date',date_time_parse(timeseries_hash[:max_date_time])[0])
      runner.registerValue('energy_consumption_comp_both_fans_hr',date_time_parse(timeseries_hash[:max_date_time])[1])

      # get evaporator_coil
      key_value =  "COIL COOLING DX SINGLE SPEED 1"
      variable_name = "Cooling Coil Sensible Cooling Rate"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_wh = OpenStudio.convert(timeseries_hash[:max],'Wh','Wh').get
      runner.registerValue('evap_coil_load_sensible_wh',value_wh)
      runner.registerValue('evap_coil_load_sensible_date',date_time_parse(timeseries_hash[:max_date_time])[0])
      runner.registerValue('evap_coil_load_sensible_hr',date_time_parse(timeseries_hash[:max_date_time])[1])
      variable_name = "Cooling Coil Latent Cooling Rate"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_wh = OpenStudio.convert(timeseries_hash[:max],'Wh','Wh').get
      runner.registerValue('evap_coil_load_latent_wh',value_wh)
      runner.registerValue('evap_coil_load_latent_date',date_time_parse(timeseries_hash[:max_date_time])[0])
      runner.registerValue('evap_coil_load_latent_hr',date_time_parse(timeseries_hash[:max_date_time])[1])
      variable_name = "Cooling Coil Total Cooling Rate"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      value_wh = OpenStudio.convert(timeseries_hash[:max],'Wh','Wh').get
      runner.registerValue('evap_coil_load_sensible_and_latent_wh',value_wh)
      runner.registerValue('evap_coil_load_sensible_and_latent_date',date_time_parse(timeseries_hash[:max_date_time])[0])
      runner.registerValue('evap_coil_load_sensible_and_latent_hr',date_time_parse(timeseries_hash[:max_date_time])[1])

      key_value =  "Environment"
      variable_name = "Site Outdoor Air Drybulb Temperature"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      runner.registerValue('weather_odb_c',timeseries_hash[:max])
      runner.registerValue('weather_odb_date',date_time_parse(timeseries_hash[:max_date_time])[0])
      runner.registerValue('weather_odb_hr',date_time_parse(timeseries_hash[:max_date_time])[1])
      variable_name = "Site Outdoor Air Humidity Ratio"
      timeseries_hash = process_output_timeseries(sqlFile, runner, ann_env_pd, 'Hourly', variable_name, key_value)
      runner.registerValue('weather_outdoor_humidity_ratio_c',timeseries_hash[:max])
      runner.registerValue('weather_outdoor_humidity_ratio_date',date_time_parse(timeseries_hash[:max_date_time])[1])
      runner.registerValue('weather_outdoor_humidity_ratio_hr',date_time_parse(timeseries_hash[:max_date_time])[1])

      # Annual Hourly Integrated Maxima - COP2 and Zone Table
      runner.registerValue('cop2_max_cop2','tbd')
      runner.registerValue('cop2_max_date','tbd')
      runner.registerValue('cop2_max_hr','tbd')
      runner.registerValue('cop2_min_cop2','tbd')
      runner.registerValue('cop2_min_date','tbd')
      runner.registerValue('cop2_min_hr','tbd')
      runner.registerValue('idb_max_idb','tbd')
      runner.registerValue('idb_max_date','tbd')
      runner.registerValue('idb_max_hr','tbd')
      runner.registerValue('idb_min_idb','tbd')
      runner.registerValue('idb_min_date','tbd')
      runner.registerValue('idb_min_hr','tbd')
      runner.registerValue('hr_max_humidity_ratio','tbd')
      runner.registerValue('hr_max_date','tbd')
      runner.registerValue('hr_max_hr','tbd')
      runner.registerValue('hr_min_humidity_ratio','tbd')
      runner.registerValue('hr_min_date','tbd')
      runner.registerValue('hr_min_hr','tbd')
      runner.registerValue('rh_max_relative_humidity','tbd')
      runner.registerValue('rh_max_date','tbd')
      runner.registerValue('rh_max_hr','tbd')
      runner.registerValue('rh_min_relative_humidity','tbd')
      runner.registerValue('rh_min_date','tbd')
      runner.registerValue('rh_min_hr','tbd')

      # temp array of 24 tbd strings
      hourly_single_day_array = []
      24.times.each do |i|
        hourly_single_day_array << 'tbd'
      end

      # make string from array.
      hourly_single_day_array = hourly_single_day_array.join(',')

      # Case 300 June 28th Hourly Table
      runner.registerValue('0628_hourly_energy_consumpton_compressor',hourly_single_day_array)
      runner.registerValue('0628_hourly_energy_consumpton_cond_fan',hourly_single_day_array)
      runner.registerValue('0628_hourly_evaporator_coil_load_total',hourly_single_day_array)
      runner.registerValue('0628_hourly_evaporator_coil_load_sensible',hourly_single_day_array)
      runner.registerValue('0628_hourly_evaporator_coil_load_latent',hourly_single_day_array)
      runner.registerValue('0628_hourly_zone_humidity_ratio',hourly_single_day_array)
      runner.registerValue('0628_hourly_cop2',hourly_single_day_array)
      runner.registerValue('0628_hourly_odb',hourly_single_day_array)
      runner.registerValue('0628_hourly_edb',hourly_single_day_array)
      runner.registerValue('0628_hourly_ewb',hourly_single_day_array)
      runner.registerValue('0628_hourly_outdoor_humidity_ratio',hourly_single_day_array)

      # Case 500 and 530 Average Daily Outputs
      runner.registerValue('0430_day_energy_consumption_total','tbd')
      runner.registerValue('0430_day_energy_consumption_compressor','tbd')
      runner.registerValue('0430_day_energy_consumption_supply_fan','tbd')
      runner.registerValue('0430_day_energy_consumption_condenser_fan','tbd')
      runner.registerValue('0430_day_evaporator_coil_load_total','tbd')
      runner.registerValue('0430_day_evaporator_coil_load_sensible','tbd')
      runner.registerValue('0430_day_evaporator_coil_load_latent','tbd')
      runner.registerValue('0430_day_zone_humidity_ratio','tbd')
      runner.registerValue('0430_day_cop2','tbd')
      runner.registerValue('0430_day_odb','tbd')
      runner.registerValue('0430_day_edb','tbd')
      runner.registerValue('0625_day_energy_consumption_total','tbd')
      runner.registerValue('0625_day_energy_consumption_compressor','tbd')
      runner.registerValue('0625_day_energy_consumption_supply_fan','tbd')
      runner.registerValue('0625_day_energy_consumption_condenser_fan','tbd')
      runner.registerValue('0625_day_evaporator_coil_load_total','tbd')
      runner.registerValue('0625_day_evaporator_coil_load_sensible','tbd')
      runner.registerValue('0625_day_evaporator_coil_load_latent','tbd')
      runner.registerValue('0625_day_zone_humidity_ratio','tbd')
      runner.registerValue('0625_day_cop2','tbd')
      runner.registerValue('0625_day_odb','tbd')
      runner.registerValue('0625_day_edb','tbd')

    end

    # close the sql file
    sqlFile.close()

    return true
 
  end

end

# register the measure to be used by the application
BESTESTCEReporting.new.registerWithApplication
