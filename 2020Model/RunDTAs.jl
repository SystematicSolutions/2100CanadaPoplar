#
#  RunDTAs.jl
#
#  ARGS[1] - Scenario Name
#  ARGS[2] - Base Case Name
#  ARGS[3] - Output Type (ExcelDTAs, AccessDTAs)
#

   using EnergyModel
   const M = EnergyModel

   println(ARGS)

   EnergyModel.CreateDTAs(ARGS[1],ARGS[2],ARGS[3],EnergyModel)


