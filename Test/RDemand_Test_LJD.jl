import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime
import EnergyModel: @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log, checkdata

db = M.DB
year = 2020 - ITime + 1
prior = 2019 - ITime + 1
next = 2021 - ITime + 1
CTime = 2020
SceName = "Base"

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

import EnergyModel.Engine.RDemand as RD
data = RD.Data(; db=db, year=year, prior=prior, next=next, CTime=CTime, SceName=SceName)

#
checkdata(data)
#
RD.Control(data)
#
checkdata(data)
#
RD.RunAfterElectric(data)
#
checkdata(data)
#
#
# PI = data.PI
# for p in Select(PI)
#   @info PI[p]
# end
