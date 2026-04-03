#
# RunData.jl
#
using EnergyModel

@info "Creating Database - $(EnergyModel.DB)"
EnergyModel.Create_Database(EnergyModel.DB)
