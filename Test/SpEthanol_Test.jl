import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import EnergyModel: VariableArray, SetArray, checkdata, unzip

db = M.DB
year = 2020 - ITime + 1
prior = 2019 - ITime + 1
next = 2021 - ITime + 1

import EnergyModel.Engine.SpEthanol as SPE
unzip("2020Model/StartBasePromula/23.11.23 StartBasePromula.zip")

data = SPE.Data(; db=db, year=year, prior=prior, next=next);
checkdata(data)
# Note: EtCR gets read in for all years because it's needed for both the current 
# year and earlier years 
SPE.EthanolSupply(data)
checkdata(data)
SPE.PriceEthanol(data)
checkdata(data)
#
