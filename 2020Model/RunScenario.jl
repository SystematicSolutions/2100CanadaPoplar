#
#  RunScenario.jl - Unzip the Start database
#
#  %1 - Beginning Year
#  %2 - Ending Year
#  %3 - Scenario Name
#  %4 - Base Case
#  %5 - Reference Case
#  %6 - Oil and Gas Reference Case
#  %7 - Scenario for zInitial in Access outputs
#  %8 - TIM Investments Case (see Jeff)
#  %9 - DTA List "Short" or blank
#  %9 Julia "EnergyModel.DB"
#

using EnergyModel

EnergyModel.RunScenario(ARGS[1], ARGS[2], ARGS[3],ARGS[4],ARGS[5],ARGS[6],ARGS[7],ARGS[8],EnergyModel.DB)
