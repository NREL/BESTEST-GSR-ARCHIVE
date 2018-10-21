module BestestResults

  # define cases for section 5.2.3
  def self.populate_common_info(program = "EP")

    hash = {}

    if program == "OS"
      hash[:program_name_and_version] = "OpenStudio 2.7.0"
      hash[:program_version_release_date] = "10/12/2018"
      hash[:program_name_short] = "OS"
    else
      hash[:program_name_and_version] = "EnergyPlus 9.0.1"
      hash[:program_version_release_date] = "10/9/2018"
      hash[:program_name_short] = "E+"
    end

    hash[:results_submission_date] = "10/21/2018"
    hash[:organization] = "National Renewable Energy Laboratory"
    hash[:organization_short] = "NREL"

    return hash

  end

end
