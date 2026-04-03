import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import EnergyModel: VariableArray, SetArray, checkdata, unzip

db = M.DB
year = 2020 - ITime + 1
prior = 2019 - ITime + 1
next = 2021 - ITime + 1
CTime = 2020

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

import EnergyModel.Engine.SuPollutionMarket as SPM
data = SPM.Data(; db=db, year=year, prior=prior, next=next, CTime=CTime);

#
checkdata(data)
#
SPM.InitializeMarkets(data)
checkdata(data)
#
UseCurrentOrNext = "Current"
SPM.ImpactOnFuelPrices(data,UseCurrentOrNext)
checkdata(data)
#
SPM.CapControl(data)
checkdata(data)
#
SPM.Control(data)
checkdata(data)
#
SPM.FinalizeMarkets(data)
checkdata(data)
#
CIt = 1    # CIt - Current iteration
NIt = 2    # NIt - Next Iteration
PIt = 1    # PIt - Privious Iteration
SPM.IterCostOfPermits(data, 105, CIt, NIt, PIt)

PIt = max(CIt - 1, 1)
NIt = CIt + 1
CIt = CIt + 1
SPM.IterCostOfPermits(data, 105, CIt, NIt, PIt)

PIt = max(CIt - 1, 1)
NIt = CIt + 1
CIt = CIt + 1
SPM.IterCostOfPermits(data, 105, CIt, NIt, PIt)

PIt = max(CIt - 1, 1)
NIt = CIt + 1
CIt = CIt + 1
SPM.IterCostOfPermits(data, 105, CIt, NIt, PIt)

