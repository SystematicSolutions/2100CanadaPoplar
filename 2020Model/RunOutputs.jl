#
# RunOutputs.jl
#
using EnergyModel
const M = EnergyModel

cp(M.Start_DB, M.DB, force=true)
mkpath(M.OutputFolder)
M.rm_dir_contents(M.OutputFolder)

SceName = "Start"
@info "RunOutputs.jl - Generate Outputs for $SceName - $(EnergyModel.DB)"
EnergyModel.GenerateOutputs(EnergyModel.DB, SceName)

cp(M.OutputFolder, M.Start_Folder, force=true)
cp(M.DB, M.Start_DB, force=true)
