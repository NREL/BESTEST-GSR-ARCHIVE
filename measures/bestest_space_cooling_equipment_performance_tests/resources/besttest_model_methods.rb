module BestestModelMethods

  # set short wave and IR int and ext surface properties for walls and roofs
  def self.set_opqaue_surface_properties(model,variable_hash)

    # arrays
    interior_materials = []
    exterior_materials = []
    altered_materials = []

    model.getDefaultConstructionSets.each do |const_set|
      next if !const_set.name.to_s.include?("BESTEST")
      ext_constructions = const_set.defaultExteriorSurfaceConstructions.get
      ext_wall = ext_constructions.wallConstruction.get.to_LayeredConstruction.get
      exterior_materials << ext_wall.layers.first.to_OpaqueMaterial.get
      interior_materials << ext_wall.layers.last.to_OpaqueMaterial.get
      ext_roof = ext_constructions.roofCeilingConstruction.get.to_LayeredConstruction.get
      exterior_materials << ext_roof.layers.first.to_OpaqueMaterial.get
      interior_materials << ext_roof.layers.last.to_OpaqueMaterial.get
      ground_constructions = const_set.defaultGroundContactSurfaceConstructions.get
      floor = ground_constructions.floorConstruction.get.to_LayeredConstruction.get
      interior_materials << floor.layers.last.to_OpaqueMaterial.get
    end

    # alter materials (ok to alter in place since no materials used on interior and exterior)
    interior_materials.uniq.each do |int_mat|
      int_mat.setThermalAbsorptance(variable_hash[:int_ir_emit])
      if !variable_hash[:int_sw_absorpt].nil?
        int_opt_double = OpenStudio::OptionalDouble.new(variable_hash[:int_sw_absorpt])
        int_mat.setSolarAbsorptance(int_opt_double)
        int_mat.setSolarAbsorptance(int_opt_double)
      end
      altered_materials << int_mat
    end
    exterior_materials.uniq.each do |ext_mat|
      ext_mat.setThermalAbsorptance(variable_hash[:ext_ir_emit])
      if !variable_hash[:int_sw_absorpt].nil?
        ext_opt_double = OpenStudio::OptionalDouble.new(variable_hash[:ext_sw_absorpt])
        ext_mat.setSolarAbsorptance(ext_opt_double)
        ext_mat.setSolarAbsorptance(ext_opt_double)
      end
      altered_materials << ext_mat
    end

    return altered_materials

  end

  def self.add_output_variable(runner,model,key_value,variable_name,reporting_frequency)

    output_variable = OpenStudio::Model::OutputVariable.new(variable_name,model)
    output_variable.setReportingFrequency(reporting_frequency)
    if !key_value.nil?
      output_variable.setKeyValue(key_value)
    end
    runner.registerInfo("Output Reqeust > #{key_value},#{output_variable.variableName}, #{reporting_frequency}")

  end

  # add options to method for variables that change across cases
  def self.create_he_system(runner,model,variable_hash)

    # BESTEST he system
    # This measure creates:
    # creates an air loop with heating only and single zone setpoint manager
    # there is no outdoor air
    # todo - has ciriculating and draft fan

    # create always on schedule
    always_on = model.alwaysOnDiscreteSchedule

    air_flow_rate = 0.355

    # get the only zone in the model
    zone = model.getThermalZones.first

    # Add air loop
    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName("BESTEST HE air loop")
    air_loop.setDesignSupplyAirFlowRate(air_flow_rate)
    runner.registerInfo("HVAC > Adding airloop named #{air_loop.name}")

    # don't know if I need to edit any air loop sizing properties
    air_loop_sizing = air_loop.sizingSystem #

    # curve for heating coil
    furnace_pldf_curve_default = OpenStudio::Model::CurveCubic.new(model)
    if variable_hash[:plr] == 1.0
      furnace_pldf_curve_default.setCoefficient1Constant(1.0)
      furnace_pldf_curve_default.setCoefficient2x(0.0)
      furnace_pldf_curve_default.setCoefficient3xPOW2(0.0)
      furnace_pldf_curve_default.setCoefficient4xPOW3(0.0)
      furnace_pldf_curve_default.setMinimumValueofx(0.0)
      furnace_pldf_curve_default.setMaximumValueofx(1.0)
    elsif variable_hash[:plr] == 0.4
      furnace_pldf_curve_default.setCoefficient1Constant(1.005519483)
      furnace_pldf_curve_default.setCoefficient2x(0.182253228)
      furnace_pldf_curve_default.setCoefficient3xPOW2(-0.527668)
      furnace_pldf_curve_default.setCoefficient4xPOW3(0.339946081)
      furnace_pldf_curve_default.setMinimumValueofx(0.0)
      furnace_pldf_curve_default.setMaximumValueofx(1.0)
    elsif variable_hash[:plr] == 0
      # todo - why does 0.0 have same curve as 1.0
      furnace_pldf_curve_default.setCoefficient1Constant(1.0)
      furnace_pldf_curve_default.setCoefficient2x(0.0)
      furnace_pldf_curve_default.setCoefficient3xPOW2(0.0)
      furnace_pldf_curve_default.setCoefficient4xPOW3(0.0)
      furnace_pldf_curve_default.setMinimumValueofx(0.0)
      furnace_pldf_curve_default.setMaximumValueofx(1.0)
    elsif variable_hash[:plr] == [0.0,0.8]
      # todo - why does this have same curve as 0.4
      furnace_pldf_curve_default.setCoefficient1Constant(1.005519483)
      furnace_pldf_curve_default.setCoefficient2x(0.182253228)
      furnace_pldf_curve_default.setCoefficient3xPOW2(-0.527668)
      furnace_pldf_curve_default.setCoefficient4xPOW3(0.339946081)
      furnace_pldf_curve_default.setMinimumValueofx(0.0)
      furnace_pldf_curve_default.setMaximumValueofx(1.0)
    elsif variable_hash[:plr] == [0.0,1.0]
      # todo - why does this have same curve as 0.4
      furnace_pldf_curve_default.setCoefficient1Constant(1.005519483)
      furnace_pldf_curve_default.setCoefficient2x(0.182253228)
      furnace_pldf_curve_default.setCoefficient3xPOW2(-0.527668)
      furnace_pldf_curve_default.setCoefficient4xPOW3(0.339946081)
      furnace_pldf_curve_default.setMinimumValueofx(0.0)
      furnace_pldf_curve_default.setMaximumValueofx(1.0)
    else
      runner.registerError("Unexpected plr variable value")
      returnf false
    end

    # Add heating coil
    htg_coil = OpenStudio::Model::CoilHeatingGas.new(model,always_on)
    htg_coil.setGasBurnerEfficiency(variable_hash[:ss_eff] / 100.0 )
    htg_coil.setNominalCapacity(variable_hash[:capacity] * 1000.0)
    htg_coil.setPartLoadFractionCorrelationCurve(furnace_pldf_curve_default)
    if variable_hash[:draft_fan_power] > 0.0
      # todo - is this inducing heat where we don't want it and is it cycling how we want it to
      htg_coil.setParasiticElectricLoad(variable_hash[:draft_fan_power])
    end

    # todo - FanOnOff doesn't seem to work here
    fan = OpenStudio::Model::FanOnOff.new(model,always_on)
    fan.setMaximumFlowRate(air_flow_rate)
    fan.setMotorInAirstreamFraction(0.0)
    if variable_hash[:circ_fan_power] == 0
      fan.setFanEfficiency(1.0)
      fan.setPressureRise(0.0)
      fan.setMotorEfficiency(1.0)
    elsif variable_hash[:circ_fan_power] == 200.0 and variable_hash[:circ_fan_type] == "cont"
      fan.setFanEfficiency(0.441975)
      fan.setPressureRise(249.0)
      fan.setMotorEfficiency(0.441975)
    elsif variable_hash[:circ_fan_power] == 200.0 and variable_hash[:circ_fan_type] == "cyclic"
      fan.setFanEfficiency(0.441975)
      fan.setPressureRise(249.0)
      fan.setMotorEfficiency(0.9)
    else
      runner.registerError("Unexpected circulating fan variable values")
      returnf false
    end

    # Add unitary system
    runner.registerInfo("HVAC > Adding AirLoopHVACUnitarySystem with gas heating coil and OnOff fan.")
    unitary_system = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    unitary_system.setAvailabilitySchedule(always_on)
    unitary_system.setSupplyFan(fan)
    unitary_system.setFanPlacement('BlowThrough')
    unitary_system.setHeatingCoil(htg_coil)
    unitary_system.setMaximumSupplyAirTemperature(80.0)
    unitary_system.setSupplyAirFlowRateMethodDuringHeatingOperation('SupplyAirFlowRate')
    unitary_system.setSupplyAirFlowRateDuringHeatingOperation(air_flow_rate)
    unitary_system.setControllingZoneorThermostatLocation(zone)
    puts unitary_system

    # Add the components to the air loop
    # in order from closest to zone to furthest from zone
    supply_inlet_node = air_loop.supplyInletNode
    unitary_system.addToNode(supply_inlet_node)

    # Create a diffuser and attach the zone/diffuser pair to the air loop
    diffuser = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model,always_on)
    diffuser.setMaximumAirFlowRate(air_flow_rate)
    air_loop.addBranchForZone(zone,diffuser.to_StraightComponent)

    return air_loop

  end

end
