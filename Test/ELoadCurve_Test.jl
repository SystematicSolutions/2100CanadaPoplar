import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import EnergyModel: checkdata

db = M.DB
year = 2020 - ITime + 1
current = year
prior = 2019 - ITime + 1
next = 2021 - ITime + 1
CTime = year + ITime - 1

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

import EnergyModel.Engine.ELoadCurve as ELC
# cp(raw"\\2020Model\\StartBasePromula\\database.hdf5", raw"\\2020Model\\database.hdf5"; force = true)
data = ELC.Data(; db, year, prior, next);
checkdata(data)
# All data currently good. Afgter a run:
# HDADP has NaNs: line 457 from
# HDEnergy has NaNs: line 445 from HMEnergy
# HMADP has NaNs: line 409 from HMEnergy
# HMEnergy has NaNs

ELC.ElecLoadCurvesAndSales(data);
checkdata(data)

