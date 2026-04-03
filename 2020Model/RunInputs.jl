#
# RunInputs.jl
#
using EnergyModel
const M = EnergyModel

cp(M.Process_DB, M.DB; force = true)

@info "RunInputs.jl Incorporate Inputs into the Database - $(EnergyModel.DB)"
EnergyModel.IncorporateInputs(EnergyModel.DB)

mkpath(M.Start_Folder)
M.rm_dir_contents(M.Start_Folder)
cp(M.DB, M.Start_DB; force = true)
