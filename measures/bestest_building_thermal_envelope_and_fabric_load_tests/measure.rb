# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# load library to map case to model variables
require "#{File.dirname(__FILE__)}/resources/besttest_case_var_lib"

# start the measure
class BESTESTBuildingThermalEnvelopeAndFabricLoadTests < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "BESTEST Building Thermal Envelope and Fabric Load Tests"
  end

  # human readable description
  def description
    return "Creates test cases described in ASHRAE Standard 140-2014 sections 5.2.1, 5.2.2, and 5.2.3."
  end

  # human readable description of modeling approach
  def modeler_description
    return "This is intended to run on an empty model. It will create the proper model associate it with the proper weather file, and add in necessary output requests. Internally to the measure the test case argument will be mapped to the proper inputs needed to assemble the model. The measure will make some objects on the fly, other objects will be pulled from existing data resources. This measure creates cases described all of section 5.2 except for section 5.2.4 - Ground-Coupled Slab-on-Grade Analytical Verification Tests."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make choice argument for test case
    choices = OpenStudio::StringVector.new
    variable_hash_lookup = BestestCaseVarLib.bestest_5_2_3_case_defs
    variable_hash_lookup.each do |k,v|
      choices << k
    end
    case_num = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("case_num", choices,true)
    case_num.setDisplayName("Test Case Number")
    case_num.setDescription("Measure will generate selected test case.")
    case_num.setDefaultValue("600")
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

    # report initial condition of model
    runner.registerInitialCondition("The initial model named #{model.getBuilding.name} has #{model.numObjects} objects.")

    # map case number to arguments and report back arguments
    variable_hash = BestestCaseVarLib.bestest_5_2_3_case_lookup(case_num,runner)
    if variable_hash == false
      runner.registerError("Didn't find #{case_num} in model variable hash.")
      return false
    end

    # rename the building
    model.getBuilding.setName("BESTEST Case #{case_num}")

    # todo - Adjust simulation settings if necessary

    # todo - Add weather file and design day objects

    # todo - Add envelope
    # todo - add helper method to load geometry, pass in model name from here
    if [0, nil].include? variable_hash[:glass_area]
      # add in geometry with no fenestration
    elsif variable_hash[:glass_area] == 12.0 and variable_hash[:orient] == 'S'
      if variable_hash[:shade] == false
        # add in south glazing without an overhang
      elsif variable_hash[:shade] == 1.0 and variable_hash[:shade_type] == 'H'
        # add in south glazing with an overhang
      else
        runner.registerError("Unexpected Geometry Variables for South Overhangs.")
      end
    elsif variable_hash[:glass_area] == 6.0 and variable_hash[:orient] == 'EW'
      if variable_hash[:shade] == false
        # add in east/west glazing without an overhang
      elsif variable_hash[:shade] == 1.0 and variable_hash[:shade_type] == 'HV'
        # add in east/west glazing with an overhang
      else
        runner.registerError("Unexpected Geometry Variables for East/West Overhangs.")
      end
    elsif variable_hash[:custom] == true and case_num.include? '960'
      # add in sun space geometry
    else
      runner.registerError("Unexpected Geometry Variables.")
    end

    # todo - Add constructions

    # todo - Add infiltration

    # todo - Add internal loads

    # todo - Add other objects

    # todo - Add output requests

    # report final condition of model
    runner.registerFinalCondition("The final model named #{model.getBuilding.name} has #{model.numObjects} objects.")

    return true

  end
  
end

# register the measure to be used by the application
BESTESTBuildingThermalEnvelopeAndFabricLoadTests.new.registerWithApplication
