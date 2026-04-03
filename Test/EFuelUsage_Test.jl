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

#
EF.RunFuelUsage(data)
#

# unit = 14
# (; Fuel,FuelEP) = data
# (; GCFA,GCFANet,UnFlFr,UnGC,UnGCNet) = data
# fuelep = Select(FuelEP)
# fuelep = fuelep[sortperm(UnFlFr[unit,fuelep], rev = true)]
# largest = first(fuelep)

# for fuel in Select(Fuel)
#   if Fuel[fuel] == FuelEP[largest]
#     @info Fuel[fuel] fuel
#     @info FuelEP[largest] largest
#   end
# end


# @info FlPlnMap


checkdata(data)

