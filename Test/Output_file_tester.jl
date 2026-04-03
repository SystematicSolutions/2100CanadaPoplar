#
# Output File Tester.jl
#
# using EnergyModel
# const M = EnergyModel

# SceName = "StartBase"
# BCName  = "StartBase"

# @info "RunDTAsSummary.jl - Generate Outputs for $SceName - $(EnergyModel.DB)"
# EnergyModel.CreateDTAs(SceName, BCName, EnergyModel)

# SceName = "Base"
# BCName  = "Base"

# @info "RunDTAsSummary.jl - Generate Outputs for $SceName - $(EnergyModel.DB)"
# EnergyModel.CreateDTAs(SceName, BCName, EnergyModel)

include("C:/2020GIT/2020CanadaRedwood/Core/Core.jl")

include("C:/2020GIT/2020CanadaRedwood/Output/ExcelOutput/SupplyBalance.jl")

# SupplyBalance_DtaControl("c:\\2020GIT\\2020CanadaRedwood\\2020Model\\database.hdf5", "Base")

