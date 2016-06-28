module BestestModelMethods

  # set short wave and IR int and ext surface properties for walls and roofs
  def self.set_opqaue_surface_properties(model,variable_hash)

    # todo - see if safe to alter materials in place of if they need to be cloned.

    # arrays
    interior_materials = []
    exterior_materials = []
    altered_materials = []

    # gather interior and exterior materials for exterior wall and roof constructions
    const_set = model.getBuilding.defaultConstructionSet.get
    ext_constructions = const_set.defaultExteriorSurfaceConstructions.get
    ext_wall = ext_constructions.wallConstruction.get.to_LayeredConstruction.get
    exterior_materials << ext_wall.layers.first.to_OpaqueMaterial.get
    interior_materials << ext_wall.layers.last.to_OpaqueMaterial.get
    ext_roof = ext_constructions.roofCeilingConstruction.get.to_LayeredConstruction.get
    exterior_materials << ext_roof.layers.first.to_OpaqueMaterial.get
    interior_materials << ext_roof.layers.last.to_OpaqueMaterial.get

    # alter materials
    interior_materials.each do |int_mat|
      int_mat.setThermalAbsorptance(variable_hash[:int_ir_emit])
      if !variable_hash[:int_sw_absorpt].nil?
        int_opt_double = OpenStudio::OptionalDouble.new(variable_hash[:int_sw_absorpt])
        int_mat.setSolarAbsorptance(int_opt_double)
        int_mat.setSolarAbsorptance(int_opt_double)
      end
      altered_materials << int_mat
    end
    exterior_materials.each do |ext_mat|
      ext_mat.setThermalAbsorptance(variable_hash[:ext_ir_emit])
      if !variable_hash[:int_sw_absorpt].nil?
        ext_opt_double = OpenStudio::OptionalDouble.new(variable_hash[:ext_sw_absorpt])
        ext_mat.setSolarAbsorptance(ext_opt_double)
        ext_mat.setSolarAbsorptance(ext_opt_double)
      end
      altered_materials << ext_mat
    end

    # todo - address sunspace model
    # more than one const set to look at
    # also need to look at interior wall

    return altered_materials

  end

end
