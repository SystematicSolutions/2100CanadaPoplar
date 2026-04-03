#
# Policy File Tester.jl
#
using EnergyModel
const M = EnergyModel

import EnergyModel: SetArray, VariableArray, ReadDisk, WriteDisk, Select, HisTime, ITime, MaxTime, First, Future, Final, finite_inverse, finite_divide, finite_power, finite_exp, finite_log, @finite_math, @autoinfiltrate

include("../Policy/HDV2.jl")
