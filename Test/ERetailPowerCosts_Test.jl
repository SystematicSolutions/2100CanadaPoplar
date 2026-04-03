import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log

db = M.DB
year = 2020 - ITime + 1
current = 2020 - ITime + 1
prior = 2019 - ITime + 1
next = 2021 - ITime + 1
# CTime = 2020

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

import EnergyModel.Engine.ERetailPowerCosts as ERPC
data = ERPC.Data(; db=db, year=year, prior=prior, next=next)

#
ERPC.ElectricCosts(data)
#
