import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import EnergyModel: checkdata, VariableArray, SetArray, unzip

db = M.DB
year = 2020 - ITime + 1
current = 2020 - ITime + 1
prior = 2019 - ITime + 1
next = 2021 - ITime + 1

# unzip("2020Model/BasePromula/23.11.23 BasePromula.zip")
import EnergyModel.Engine.SpBiofuel as N
data = N.Data(; db, year, prior, next);

checkdata(data)
#
N.SupplyBiofuel(data);
N.PriceBiofuel(data);
#
checkdata(data)
#
