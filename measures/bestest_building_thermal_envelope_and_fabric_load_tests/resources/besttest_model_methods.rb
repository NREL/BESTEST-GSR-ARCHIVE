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

  # create he case hvac systems
  def self.create_he_system(runner,model,variable_hash)

    # BESTEST he system
    # This measure creates:
    # creates an air loop with AirLoopHVACUnitarySystem object
    # AirLoopHVACUnitarySystem has CoilHeatingGas and OnOffFan

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

    # Add FanOnOff
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

  # create ce case hvac systems
  def self.create_ce_system(runner,model,variable_hash,case_num)

    # BESTEST ce system
    # This measure creates:
    # creates an air loop with AirLoopHVACUnitarySystem object
    # AirLoopHVACUnitarySystem has CoilHeatingGas and OnOffFan

    # create always on schedule
    always_on = model.alwaysOnDiscreteSchedule

    air_flow_rate = 1.888

    # get the only zone in the model
    zone = model.getThermalZones.first

    # Add air loop
    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName("BESTEST CE air loop")
    air_loop.setDesignSupplyAirFlowRate(air_flow_rate)
    runner.registerInfo("HVAC > Adding airloop named #{air_loop.name}")

    # todo - add in variables from variable_hash

    # Add curve
    clg_cap_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
    clg_cap_f_of_temp.setCoefficient1Constant(0.825119244)
    clg_cap_f_of_temp.setCoefficient2x(0.014461436)
    clg_cap_f_of_temp.setCoefficient3xPOW2(0.000525383)
    clg_cap_f_of_temp.setCoefficient4y(-0.003805859)
    clg_cap_f_of_temp.setCoefficient5yPOW2(-2.71284E-05)
    clg_cap_f_of_temp.setCoefficient6xTIMESY(-0.000198505)
    clg_cap_f_of_temp.setMinimumValueofx(0.0)
    clg_cap_f_of_temp.setMaximumValueofx(100.0)
    clg_cap_f_of_temp.setMinimumValueofy(0.0)
    clg_cap_f_of_temp.setMaximumValueofy(100.0)

    # Add curve
    clg_cap_f_of_flow = OpenStudio::Model::CurveQuadratic.new(model)
    clg_cap_f_of_flow.setCoefficient1Constant(1.0)
    clg_cap_f_of_flow.setCoefficient2x(0.0)
    clg_cap_f_of_flow.setCoefficient3xPOW2(0.0)
    clg_cap_f_of_flow.setMinimumValueofx(0.0)
    clg_cap_f_of_flow.setMaximumValueofx(1.0)

    # Add curve
    clg_energy_input_ratio_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
    clg_energy_input_ratio_f_of_temp.setCoefficient1Constant(0.630055851)
    clg_energy_input_ratio_f_of_temp.setCoefficient2x(-0.011998189)
    clg_energy_input_ratio_f_of_temp.setCoefficient3xPOW2(0.000136923)
    clg_energy_input_ratio_f_of_temp.setCoefficient4y(0.014636637)
    clg_energy_input_ratio_f_of_temp.setCoefficient5yPOW2(0.000164506)
    clg_energy_input_ratio_f_of_temp.setCoefficient6xTIMESY(-0.000238463)
    clg_energy_input_ratio_f_of_temp.setMinimumValueofx(0.0)
    clg_energy_input_ratio_f_of_temp.setMaximumValueofx(100.0)
    clg_energy_input_ratio_f_of_temp.setMinimumValueofy(0.0)
    clg_energy_input_ratio_f_of_temp.setMaximumValueofy(100.0)

    # Add curve
    clg_energy_input_ratio_f_of_flow = OpenStudio::Model::CurveQuadratic.new(model)
    clg_energy_input_ratio_f_of_flow.setCoefficient1Constant(1.0)
    clg_energy_input_ratio_f_of_flow.setCoefficient2x(0.0)
    clg_energy_input_ratio_f_of_flow.setCoefficient3xPOW2(0.0)
    clg_energy_input_ratio_f_of_flow.setMinimumValueofx(0.0)
    clg_energy_input_ratio_f_of_flow.setMaximumValueofx(1.0)

    # Add curve
    clg_part_load_ratio = OpenStudio::Model::CurveQuadratic.new(model)
    clg_part_load_ratio.setCoefficient1Constant(0.771)
    clg_part_load_ratio.setCoefficient2x(0.229)
    clg_part_load_ratio.setCoefficient3xPOW2(0.0)
    clg_part_load_ratio.setMinimumValueofx(0.0)
    clg_part_load_ratio.setMaximumValueofx(1.0)

    # Add cooling coil
    clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model,
                                                               always_on,
                                                               clg_cap_f_of_temp,
                                                               clg_cap_f_of_flow,
                                                               clg_energy_input_ratio_f_of_temp,
                                                               clg_energy_input_ratio_f_of_flow,
                                                               clg_part_load_ratio)

    # customize cooling coil
    clg_coil.setRatedTotalCoolingCapacity (33280.0)
    clg_coil.setRatedSensibleHeatRatio(0.78245)
    clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(3.0448))
    clg_coil.setRatedAirFlowRate(air_flow_rate)

    # Add FanOnOff
    fan = OpenStudio::Model::FanOnOff.new(model,always_on)
    fan.setMaximumFlowRate(air_flow_rate)
    fan.setMotorInAirstreamFraction(1.0)
    fan.setFanEfficiency(0.11374)
    fan.setPressureRise(74.7)
    fan.setMotorEfficiency(0.94)

    # Add unitary system
    runner.registerInfo("HVAC > Adding AirLoopHVACUnitarySystem with dx cooling coil and OnOff fan.")
    unitary_system = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    unitary_system.setAvailabilitySchedule(always_on)
    unitary_system.setSupplyFan(fan)
    unitary_system.setFanPlacement('DrawThrough')
    unitary_system.setCoolingCoil(clg_coil)
    unitary_system.setSupplyAirFlowRateMethodDuringCoolingOperation('SupplyAirFlowRate')
    unitary_system.setSupplyAirFlowRateDuringCoolingOperation(air_flow_rate)
    unitary_system.setSupplyAirFlowRateMethodWhenNoCoolingorHeatingisRequired('SupplyAirFlowRate')
    if case_num.include?('CE5')
      unitary_system.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0.0)
    else
      unitary_system.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(air_flow_rate)
    end
    unitary_system.setControllingZoneorThermostatLocation(zone)
    unitary_system.setSupplyAirFanOperatingModeSchedule(always_on)

    # Add the components to the air loop
    # in order from closest to zone to furthest from zone
    supply_inlet_node = air_loop.supplyInletNode
    unitary_system.addToNode(supply_inlet_node)

    # todo - add logic for CE1 and CE2
    # todo - finish adding logic for CE5 cases

    # see of OA system is needed
    if !(case_num.include?('CE1') || case_num.include?('CE2') || case_num.include?('CE5'))

      # setup oa case specific variables
      oa_min = nil
      oa_sch = nil
      ctrl_type = nil
      lockout_type = nil
      if case_num.include?('CE320')
        oa_min = 0.0
      elsif case_num.include?('CE330')
        oa_min = air_flow_rate
        oa_sch = resource_model.getModelObjectByName("CE330_oa").get.to_ScheduleRuleset.get
      elsif case_num.include?('CE340')
        oa_min = air_flow_rate
        oa_sch = resource_model.getModelObjectByName("CE340_oa").get.to_ScheduleRuleset.get
      elsif case_num.include?('CE400')
        ctrl_type = 'DifferentialDryBulb'
      elsif case_num.include?('CE410')
        lockout_type = 'LockoutWithCompressor'
      elsif case_num.include?('CE430') || case_num.include?('CE440')
        ctrl_type = 'DifferentialEnthalpy'
      end
      if oa_min.nil? then oa_min = 0.283166667 end
      if ctrl_type.nil? then ctrl_type = 'NoEconomizer' end
      if lockout_type.nil? then lockout_type = 'NoLockout' end

      # add oa system
      runner.registerInfo("HVAC > Adding Outdoor Air System.")
      oa_controller = OpenStudio::Model::ControllerOutdoorAir.new(model)
      oa_controller.setMinimumOutdoorAirFlowRate(oa_min)
      oa_controller.setMaximumOutdoorAirFlowRate(air_flow_rate)
      oa_controller.setEconomizerControlType(ctrl_type)
      oa_controller.setEconomizerControlActionType('ModulateFlow')
      if case_num.include?('CE420')
        oa_controller.setEconomizerMaximumLimitDryBulbTemperature(20.0)
      end
      if case_num.include?('CE440')
        oa_controller.setEconomizerMaximumLimitEnthalpy(47250.0)
      end
      #oa_controller.setEconomizerMaximumLimitDewpointTemperature(0.0)
      #oa_controller.setEconomizerMinimumLimitDryBulbTemperature(0.0)
      oa_controller.setLockoutType(lockout_type)
      oa_controller.setMinimumLimitType('FixedMinimum')
      if !oa_sch.nil?
        oa_controller.setMinimumOutdoorAirSchedule(oa_sch)
      end
      oa_system = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model,oa_controller)
      oa_system.addToNode(supply_inlet_node)
    end

    # Create a diffuser and attach the zone/diffuser pair to the air loop
    diffuser = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model,always_on)
    diffuser.setMaximumAirFlowRate(air_flow_rate)
    air_loop.addBranchForZone(zone,diffuser.to_StraightComponent)

    return air_loop

  end

end
