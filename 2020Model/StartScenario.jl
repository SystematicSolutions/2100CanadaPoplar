#
#  StartScenario.jl - Unzip the Start database
#
#  %1 - Start database name
#  %2 - Scenario Name
#  %3 - Base Case
#  %4 - Reference Case
#  %5 - Oil and Gas Reference Case
#  %6 - Scenario for zInitial in Access outputs
#  %7 - Case used for DInv, PInv
#

using EnergyModel

EnergyModel.StartScenario(ARGS[1], ARGS[2], ARGS[3],ARGS[4],ARGS[5],ARGS[6],ARGS[7])
  
