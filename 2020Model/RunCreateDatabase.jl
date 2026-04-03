#
# RunCreateDatabase.jl
#

using EnergyModel

@info "RunCreateDatabase.jl - Create Process Database - $(EnergyModel.DB)"
EnergyModel.Create_Database(EnergyModel.DB)

