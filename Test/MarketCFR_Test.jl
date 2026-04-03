import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
using HDF5, DataFrames, CSV, Printf

db = M.DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

import EnergyModel.Outputs.Outputs as O
include("Outputs\\MarketCFR.jl")

data = O.MarketCFRData(; db=db)

#
O.HydroControl(data)
#
