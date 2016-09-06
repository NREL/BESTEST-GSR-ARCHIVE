# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'

require "#{File.dirname(__FILE__)}/resources/os_lib_reporting_bestest"
require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"

#start the measure
class BESTESTHEReporting < OpenStudio::Ruleset::ReportingUserScript

  # human readable name
  def name
    return "BESTEST HE Reporting"
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

    # total furnace load
    query = 'SELECT Value FROM tabulardatawithstrings WHERE '
    query << "ReportName='SensibleHeatGainSummary' and "
    query << "ReportForString='Entire Facility' and "
    query << "TableName='Annual Building Sensible Heat Gain Components' and "
    query << "RowName='ZONE ONE' and "
    query << "ColumnName='HVAC Terminal Unit Sensible Air Heating' and "
    query << "Units='GJ';"
    query_results = sqlFile.execAndReturnFirstDouble(query)
    if query_results.empty?
      runner.registerWarning('Did not find value for sensible air heating for ZONE ONE.')
      return false
    else
      runner.registerValue('total_furnace_load',query_results.get,'GJ')
    end

    # total furnace input
    query = 'SELECT Value FROM tabulardatawithstrings WHERE '
    query << "ReportName='AnnualBuildingUtilityPerformanceSummary' and "
    query << "ReportForString='Entire Facility' and "
    query << "TableName='End Uses' and "
    query << "RowName='Heating' and "
    query << "ColumnName='Natural Gas' and "
    query << "Units='GJ';"
    query_results = sqlFile.execAndReturnFirstDouble(query)
    if query_results.empty?
      runner.registerWarning('Did not find value for heating end use.')
      return false
    else
      runner.registerValue('total_furnace_input',query_results.get,'GJ')

      # calculate average rate from this (per formula in section 6.4.1.3)
      hhv = 38.0 # MJ/m^3
      avg_fuel_rate = (query_results.get/(hhv * 7.776 * 10**6)) * 1000.0
      runner.registerValue('average_fuel_consumption',avg_fuel_rate,'m^3/sec')
    end

    # annual fans
    query = 'SELECT Value FROM tabulardatawithstrings WHERE '
    query << "ReportName='AnnualBuildingUtilityPerformanceSummary' and "
    query << "ReportForString='Entire Facility' and "
    query << "TableName='End Uses' and "
    query << "RowName='Fans' and "
    query << "ColumnName='Electricity' and "
    query << "Units='GJ';"
    query_results = sqlFile.execAndReturnFirstDouble(query)
    if query_results.empty?
      runner.registerWarning('Did not find value for fan end use.')
      return false
    else
      runner.registerValue('fan_energy',OpenStudio.convert(query_results.get,'GJ','kWh').get,'kWh')
    end

    # get time series data for main zone
    array_temps = []
    ann_env_pd = OsLib_Reporting_Bestest.ann_env_pd(sqlFile)
    if ann_env_pd

      # create array from values
      output_timeseries = sqlFile.timeSeries(ann_env_pd, 'Hourly', 'Zone Mean Air Temperature', 'ZONE ONE')
      if output_timeseries.is_initialized # checks to see if time_series exists

        output_timeseries = output_timeseries.get.values
        for i in 0..(output_timeseries.size - 1)

          # using this to get average
          array_temps << output_timeseries[i]

        end
      else
        runner.registerWarning("Didn't find data for Zone Mean Air Temperature")
      end # end of if output_timeseries.is_initialized

    end

    # store min and max and avg temps as register value
    runner.registerValue('minimum_zone_temperature',array_temps.min,'C')
    runner.registerValue('maximum_zone_temperature',array_temps.max,'C')
    runner.registerValue('mean_zone_temperature',array_temps.reduce(:+) / array_temps.size.to_f,'C')

    # close the sql file
    sqlFile.close()

    return true
 
  end

end

# register the measure to be used by the application
BESTESTHEReporting.new.registerWithApplication
