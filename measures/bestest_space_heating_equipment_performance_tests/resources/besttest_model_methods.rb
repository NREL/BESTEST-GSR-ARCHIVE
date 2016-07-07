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

end
