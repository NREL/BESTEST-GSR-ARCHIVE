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
    # todo - confirm that I mapped values correctly
    # todo - add in check if int_sw_absorpt is NA
    interior_materials.each do |int_mat|
      #int_mat.setThermalAbsorptance(variable_hash[:int_ir_emit])
      #int_mat.setSolarAbsorptance(variable_hash[:int_sw_absorpt])
      #altered_materials << altered_materials
    end
    interior_materials.each do |int_mat|
      #int_mat.setThermalAbsorptance(variable_hash[:int_ir_emit])
      #int_mat.setSolarAbsorptance(variable_hash[:int_sw_absorpt])
      #altered_materials << altered_materials
    end

    # todo - address sunspace model
    # more than one const set to look at
    # also need to look at interior wall

    return altered_materials

  end

end
