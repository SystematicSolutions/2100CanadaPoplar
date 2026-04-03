import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime
import EnergyModel: @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log, checkdata

db = M.DB
year = 2021 - ITime + 1
current = 2021 - ITime + 1
prior = 2020 - ITime + 1
next = 2022 - ITime + 1
CTime = 2021

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

import EnergyModel.Engine.EFuelUsage as EF
data = EF.Data(; db=db, year=year, prior=prior, next=next, CTime=CTime)

using Profile 
ProfileView.view(nothing) 

#
#@profile EF.RunFuelUsage(data)
#@profview EF.RunFuelUsage(data)
#@profview EF.UnitSummary(data)

