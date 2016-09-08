# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# load library to map case to model variables
require "#{File.dirname(__FILE__)}/resources/besttest_case_var_lib"
require "#{File.dirname(__FILE__)}/resources/besttest_model_methods"
require "#{File.dirname(__FILE__)}/resources/epw"

# start the measure
class BESTESTSpaceCoolingEquipmentPerformanceTests < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "BESTEST Space Cooling Equipment Performance Tests"
  end
  # human readable description
  def description
    return "Creates test cases described in ASHRAE Standard 140-2014 sections 5.3.1, 5.3.2, 5.33, and 5.3.4."
  end
  # human readable description of modeling approach
  def modeler_description
    return "This is intended to run on an empty model. It will create the proper model associate it with the proper weather file, and add in necessary output requests. Internally to the measure the test case argument will be mapped to the proper inputs needed to assemble the model. The measure will make some objects on the fly, other objects will be pulled from existing data resources. This measure creates cases described all of section 5.3."
  end
  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make choice argument for test case
    choices = OpenStudio::StringVector.new
    variable_hash_lookup = BestestCaseVarLib.bestest_5_3_case_defs
    variable_hash_lookup.each do |k,v|
      choices << k
    end

    # creates arg names for spreadsheet
    array = []
    choices.each do |choice|
      array << "'#{choice}'"
    end
    #puts "String for spreadsheet"
    #puts "[#{array.join(",")}]"

    case_num = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("case_num", choices,true)
    case_num.setDisplayName("Test Case Number")
    case_num.setDescription("Measure will generate selected test case.")
    case_num.setDefaultValue("CE100 - Base-Case Building and Mechanical System")
    args << case_num

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    case_num = runner.getStringArgumentValue("case_num", user_arguments)
    runner.registerInfo("Full case number: #{case_num}")

    # report initial condition of model
    runner.registerInitialCondition("The initial model named #{model.getBuilding.name} has #{model.numObjects} objects.")

    # map case number to arguments and report back arguments
    variable_hash = BestestCaseVarLib.bestest_5_3_case_lookup(case_num,runner)
    if variable_hash == false
      runner.registerError("Didn't find #{case_num} in model variable hash.")
      return false
    else
      # should return one item, get the hash
      variable_hash = variable_hash.first
    end

    # Adjust simulation settings if necessary
    BestestModelMethods.config_sim_settings(runner,model,'TARP','TARP')

    # Add weather file (won't work in apply measures now)
    top_dir = File.dirname(__FILE__)
    weather_dir = "#{top_dir}/resources/"
    weather_file_name = "#{variable_hash[:epw]}TM2.epw"
    weather_file = File.join(weather_dir, weather_file_name)
    epw_file = OpenStudio::EpwFile.new(weather_file)
    weather_object = OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get
    weather_name = "#{epw_file.city}_#{epw_file.stateProvinceRegion}_#{epw_file.country}"
    weather_lat = epw_file.latitude
    weather_lon = epw_file.longitude
    weather_time = epw_file.timeZone
    weather_elev = epw_file.elevation
    site = model.getSite
    site.setName(weather_name)
    site.setLatitude(weather_lat)
    site.setLongitude(weather_lon)
    site.setTimeZone(weather_time)
    site.setElevation(weather_elev)
    runner.registerInfo("Weather > setting weather to #{weather_object.url.get}")

    # need design days for OpenStudio to run, but values should not matter
    summer_design_day = OpenStudio::Model::DesignDay.new(model)
    winter_design_day = OpenStudio::Model::DesignDay.new(model)
    winter_design_day.setDayType('WinterDesignDay')

    # Lookup envelope
    file_to_clone = nil
    if case_num.include? 'CE1'
      file_to_clone = 'Bestest_Geo_CE100.osm'
    elsif case_num.include? 'CE2'
    file_to_clone = 'Bestest_Geo_CE100.osm'
    elsif case_num.include? 'CE3'
      file_to_clone = 'Bestest_Geo_CE300.osm'
    elsif case_num.include? 'CE4'
      file_to_clone = 'Bestest_Geo_CE300.osm'
    elsif case_num.include? 'CE5'
      file_to_clone = 'Bestest_Geo_CE300.osm'
    else
      runner.registerError("Unexpected Geometry Variables.")
      return false
    end

    # Add envelope from external file
    runner.registerInfo("Envelope > Adding spaces and zones from #{file_to_clone}")
    translator = OpenStudio::OSVersion::VersionTranslator.new
    geo_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/resources/" + "#{file_to_clone}")
    geo_model = translator.loadModel(geo_path).get
    geo_model.getBuilding.clone(model)

    # Load resource file
    file_resource = "bestest_resources.osm"
    runner.registerInfo("Shared Resources > Loading #{file_resource}")
    translator = OpenStudio::OSVersion::VersionTranslator.new
    resource_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/resources/" + "#{file_resource}")
    resource_model = translator.loadModel(resource_path).get

    # Lookup sensible internal load
    if variable_hash[:int_gen_sensible].is_a? Numeric
      inst_to_clone = resource_model.getModelObjectByName("CE_sens_generic_inst").get.to_OtherEquipment.get
    elsif variable_hash[:int_gen_sensible] == 'mid'
      inst_to_clone = resource_model.getModelObjectByName("CE_sens_mid_inst").get.to_OtherEquipment.get
    elsif variable_hash[:int_gen_sensible] == 'high'
      inst_to_clone = resource_model.getModelObjectByName("CE_sens_high_inst").get.to_OtherEquipment.get
    elsif variable_hash[:int_gen_sensible] == 'mid2'
      inst_to_clone = resource_model.getModelObjectByName("CE_sens_mid2_inst").get.to_OtherEquipment.get
    elsif variable_hash[:int_gen_sensible] == 'high2'
      inst_to_clone = resource_model.getModelObjectByName("CE_sens_high2_inst").get.to_OtherEquipment.get
    else
      runner.registerError("Unexpected internal load sensible value")
      return false
    end

    # add load
    load_inst_sens = inst_to_clone.clone(model).to_OtherEquipment.get
    load_inst_sens.setSpace(model.getSpaces.first)
    runner.registerInfo("Internal Loads > Adding #{load_inst_sens.name} to #{model.getSpaces.first.name}.")

    # if generic update the value
    if variable_hash[:int_gen_sensible].is_a? Numeric
      load_def = load_inst_sens.definition.to_OtherEquipmentDefinition.get
      load_def.setDesignLevel(variable_hash[:int_gen_sensible])
      runner.registerInfo("Internal Loads > Setting Design Level to #{load_def.designLevel} W.")
    end

    # Lookup latent internal load
    if variable_hash[:int_gen_latent].is_a? Numeric
      inst_to_clone = resource_model.getModelObjectByName("CE_lat_generic_inst").get.to_OtherEquipment.get
    elsif variable_hash[:int_gen_latent] == 'mid'
      inst_to_clone = resource_model.getModelObjectByName("CE_lat_mid_inst").get.to_OtherEquipment.get
    elsif variable_hash[:int_gen_latent] == 'high'
      inst_to_clone = resource_model.getModelObjectByName("CE_lat_high_inst").get.to_OtherEquipment.get
    elsif variable_hash[:int_gen_latent] == 'mid2'
      inst_to_clone = resource_model.getModelObjectByName("CE_lat_mid2_inst").get.to_OtherEquipment.get
    elsif variable_hash[:int_gen_latent] == 'high2'
      inst_to_clone = resource_model.getModelObjectByName("CE_lat_high2_inst").get.to_OtherEquipment.get
    else
      runner.registerError("Unexpected internal load latent value")
      return false
    end

    # add load
    load_inst_lat= inst_to_clone.clone(model).to_OtherEquipment.get
    load_inst_lat.setSpace(model.getSpaces.first)
    runner.registerInfo("Internal Loads > Adding #{load_inst_lat.name} to #{model.getSpaces.first.name}.")

    # if generic update the value
    if variable_hash[:int_gen_latent].is_a? Numeric
      load_def = load_inst_lat.definition.to_OtherEquipmentDefinition.get
      load_def.setDesignLevel(variable_hash[:int_gen_latent])
      runner.registerInfo("Internal Loads > Setting Design Level to #{load_def.designLevel} W.")
    end

    # Add infiltration
    if variable_hash[:infil].nil?
      # do nothing
    elsif variable_hash[:infil] == 0.0
      # do nothing
    else
      inst_to_clone = resource_model.getModelObjectByName("infil_gen").get.to_SpaceInfiltrationDesignFlowRate.get
      infil = inst_to_clone.clone(model).to_SpaceInfiltrationDesignFlowRate.get
      infil.setAirChangesperHour(variable_hash[:infil])
      infil.setSpace(model.getSpaces.first)
      # look at note a (only cases with non zero infil should fall into this)
      if variable_hash[:b1_7_note_a]
        if case_num.include?("CE320")
          resource_sch = resource_model.getModelObjectByName("CE320_infil").get.to_ScheduleRuleset.get
          sch = resource_sch.clone(model).to_ScheduleRuleset.get
        elsif case_num.include?("CE340")
          resource_sch = resource_model.getModelObjectByName("CE340_infil").get.to_ScheduleRuleset.get
          sch = resource_sch.clone(model).to_ScheduleRuleset.get
        else
          runner.registerError("Couldn't identify case for note a")
          return false
        end
        infil.setSchedule(sch)
      end
      runner.registerInfo("Infiltration > Setting to #{infil.airChangesperHour} ACH for #{model.getSpaces.first.name}.")
    end

    # Add OA
    # todo - do I need this or should it be controlled by the hvac system only
    if variable_hash[:oa].nil?
      # do nothing
    elsif variable_hash[:oa] == 0.0
      # do nothing
    else
      inst_to_clone = resource_model.getModelObjectByName("oa_gen").get.to_DesignSpecificationOutdoorAir.get
      oa = inst_to_clone.clone(model).to_DesignSpecificationOutdoorAir.get
      oa.setOutdoorAirFlowAirChangesperHour(variable_hash[:oa])
      model.getSpaces.first.setDesignSpecificationOutdoorAir(oa)
      # look at note a
      if variable_hash[:b1_7_note_a]
        if case_num.include?("CE330")
          resource_sch = resource_model.getModelObjectByName("CE330_oa").get.to_ScheduleRuleset.get
          sch = resource_sch.clone(model).to_ScheduleRuleset.get
        elsif case_num.include?("CE340")
          resource_sch = resource_model.getModelObjectByName("CE340_oa").get.to_ScheduleRuleset.get
          sch = resource_sch.clone(model).to_ScheduleRuleset.get
        else
          runner.registerError("Couldn't identify case for note a")
          return false
        end
        oa.setOutdoorAirFlowRateFractionSchedule(sch)
      end
      runner.registerInfo("Outdoor Air > Setting to #{oa.outdoorAirFlowAirChangesperHour } ACH for #{model.getSpaces.first.name}.")
    end

    # setup clg thermostat schedule
    if variable_hash[:clg_set].is_a? Float
      clg_setp = OpenStudio::Model::ScheduleConstant.new(model)
      clg_setp.setValue(variable_hash[:clg_set])
      clg_setp.setName("#{variable_hash[:clg_set]} C")
    elsif variable_hash[:clg_set] == [25.0,35.0]
      resource_sch = resource_model.getModelObjectByName("CE350_clg").get.to_ScheduleRuleset.get
      clg_setp = resource_sch.clone(model).to_ScheduleRuleset.get
    else
      runner.registerError("Unexpected cooling setpoint variable")
      return false
    end

    # setup htg thermostat schedule
    bestest_no_htg = resource_model.getModelObjectByName("No Heating").get.to_ScheduleRuleset.get
    htg_setp = bestest_no_htg.clone(model).to_ScheduleRuleset.get

    # create thermostats
    thermostat = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
    thermostat.setCoolingSetpointTemperatureSchedule(clg_setp)
    thermostat.setHeatingSetpointTemperatureSchedule(htg_setp)
    zone = model.getThermalZones.first
    zone.setThermostatSetpointDualSetpoint(thermostat)
    runner.registerInfo("Thermostat > #{zone.name} has clg setpoint sch named #{clg_setp.name} and htg setpoint sch named #{htg_setp.name}.")

    # add in HVAC
    BestestModelMethods.create_ce_system(runner,model,resource_model,variable_hash,case_num)

    # rename the building
    model.getBuilding.setName("BESTEST Case #{case_num}")
    runner.registerInfo("Renaming Building > #{model.getBuilding.name}")

    # note: set interior solar distribution fractions isn't needed if E+ auto calcualtes it

    # Add output requests (consider adding to case hash instead of adding logic here)
    # this gather any non standard output requests. Analysis of output such as binning temps for FF will occur in reporting measure
    # Table 6-1 describes the specific day of results that will be used for testing
    hourly_variables = []

    # adding collection of ranges and timesteps for different variables
    hourly_var_feb = [] # used for Case 1xx and 2xx

    # variables for all CE cases
    hourly_variables << 'Site Outdoor Air Drybulb Temperature'
    hourly_variables << 'Site Outdoor Air Humidity Ratio'
    hourly_variables << 'Surface Inside face Temperature'
    hourly_variables << 'Surface Outside face Temperature'
    hourly_variables << 'Surface Inside Face Convection Heat Transfer Coefficient'
    hourly_variables << 'Surface Outside Face Convection Heat Transfer Coefficient'
    #hourly_variables << 'Zone Mean Air Temperature'
    #hourly_variables << 'Zone Air Temperature'
    hourly_variables << 'Zone Air Humidity Ratio'
    hourly_variables << 'Zone Air System Sensible Heating Energy'
    hourly_variables << 'Zone Air System Sensible Cooling Energy'
    hourly_variables << 'Zone Total Internal Latent Gain Energy'
    hourly_variables << 'Fan Electric Power'
    hourly_variables << 'Fan Rise in Air Temperature'
    hourly_variables << 'Fan Electric Energy'
    #hourly_variables << 'Cooling Coil Total Cooling Energy'
    #hourly_variables << 'Cooling Coil Sensible Cooling Rate'
    #hourly_variables << 'Cooling Coil Sensible Cooling Energy'
    hourly_variables << 'Cooling Coil Electric Power'
    hourly_variables << 'Cooling Coil Electric Energy'
    hourly_variables << 'Cooling Coil Latent Cooling Rate'
    hourly_variables << 'Cooling Coil Latent Cooling Energy'

    # Unitary outputs in these models vs. Zone Window Air Conditioner outputs in legacy
    hourly_variables << 'Unitary System Part Load Ratio'
    hourly_variables << 'Unitary System Total Cooling Rate'
    hourly_variables << 'Unitary System Sensible Cooling Rate'
    #hourly_variables << 'Unitary System Latent Cooling Rate'
    #hourly_variables << 'Unitary System Total Heating Rate'
    #hourly_variables << 'Unitary System Sensible Heating Rate'
    hourly_variables << 'Unitary System Latent Heating Rate'
    hourly_variables << 'Unitary System Ancillary Electric Power'
    hourly_variables << 'Unitary System Dehumidification Induced Heating Demand Rate'
    hourly_variables << 'Unitary System Fan Part Load Ratio'
    hourly_variables << 'Unitary System Compressor Part Load Ratio'
    hourly_variables << 'Unitary System Frost Control Status'

    # variables CE 1x through 2x
    if case_num.include? "CE1" or case_num.include? "CE2"
      hourly_variables << 'Site Outdoor Air Wetbulb Temperature'
      hourly_variables << 'Site Outdoor Air Dewpoint Temperature'
      hourly_variables << 'Site Outdoor Air Enthalpy'
      hourly_variables << 'Site Outdoor Air Relative Humidity'
      hourly_variables << 'Site Outdoor Air Density'
      hourly_variables << 'Site Outdoor Air Barometric Pressure'
      hourly_variables << 'Site Wind Speed'
      hourly_variables << 'Site Direct Solar Radiation Rate per Area'
      hourly_variables << 'Site Diffuse Solar Radiation Rate per Area'

      # hourly for february

      #6.3.1.1 (a,b,c,d)
      hourly_var_feb << 'Air System Electric Energy' #J
      hourly_var_feb << 'Air System DX Cooling Coil Electric Energy' #J
      hourly_var_feb << 'Air System Fan Electric Energy' #J
      # todo - can I get d directly or does d = a - b - c

      #6.3.1.2 (a,b,c)
      hourly_var_feb << 'Cooling Coil Total Cooling Rate' #W
      hourly_var_feb << 'Cooling Coil Sensible Cooling Rate' #W
      hourly_var_feb << 'Cooling Coil Latent Cooling Rate' #W

      #6.3.1.3 (a,b,c)
      hourly_var_feb << 'Unitary System Total Cooling Rate' #W
      hourly_var_feb << 'Unitary System Sensible Cooling Rate' #W
      hourly_var_feb << 'Unitary System Latent Cooling Rate' #W

      #6.3.1.4 (a,b,c)
      # a: calculated from other variables
      hourly_var_feb << 'Zone Mean Air Temperature'
      hourly_var_feb << 'Zone Mean Air Humidity Ratio'


    elsif case_num.include? "CE3"
      hourly_variables << 'System Node Temperature'
      hourly_variables << 'System Node Mass Flow Rate'
    elsif case_num.include? "CE4" or case_num.include? "CE5"
      hourly_variables << 'System Node Temperature'
      hourly_variables << 'System Node Mass Flow Rate'
      hourly_variables << 'System Node Setpoint Temperature'
      hourly_variables << 'Zone Other Equipment Radiant Heating Energy'
      hourly_variables << 'Zone Other Equipment Convective Heating Energy'
      hourly_variables << 'Zone Other Equipment Latent Gain Energy'
      hourly_variables << 'Zone Other Equipment Lost Heat Energy'
      hourly_variables << 'Zone Other Equipment Total Heating Energy'
    else
      runner.registerWarning("Unexpected Case Number")
    end

    hourly_variables.each do |variable|
      BestestModelMethods.add_output_variable(runner,model,nil,variable,'hourly')
    end

    hourly_var_feb.each do |variable|
      BestestModelMethods.add_output_variable(runner,model,nil,variable,'hourly','02/01','02/29')
    end


    # report final condition of model
    runner.registerFinalCondition("The final model named #{model.getBuilding.name} has #{model.numObjects} objects.")

    return true

  end
  
end

# register the measure to be used by the application
BESTESTSpaceCoolingEquipmentPerformanceTests.new.registerWithApplication
