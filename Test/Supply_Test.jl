import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime
import EnergyModel: @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log, checkdata

db = M.DB
year = 2020 - ITime + 1
prior = 2019 - ITime + 1
next = 2021 - ITime + 1
CTime = 2020


const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

import EnergyModel.Engine.Supply as S
data = S.Data(; db=db, year=year, prior=prior, next=next, CTime=CTime)
#
checkdata(data)
#
S.ExoSalesNonElectric(data)
#
checkdata(data)
#
S.ExoElectricSalesAndLoadCurve(data)
#
checkdata(data)
#
S.RestOfWorldLoadCurve(data)
#
checkdata(data)
#
S.LoadCurve(data)
#
checkdata(data)
#
S.SteamSupply(data)
#
checkdata(data)
#
S.DailyUse(data)
#
checkdata(data)
#
S.Accounts(data)
#
checkdata(data)
#
S.Price(data)
#
checkdata(data)
#
S.Expenditures(data)
#
checkdata(data)
#
S.IMWrite(data)
#
checkdata(data)
#
