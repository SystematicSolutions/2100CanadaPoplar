import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import EnergyModel: VariableArray, SetArray, checkdata, unzip

db = M.DB
year = 2020 - ITime + 1
prior = 2019 - ITime + 1
next = 2021 - ITime + 1

# unzip("2020Model/StartBasePromula/23.11.23 StartBasePromula.zip")

import EnergyModel.Engine.SpOProd as SO
data = SO.Data(; db=db, year=year, prior=prior, next=next);
checkdata(data)
#
SO.Control(data)
checkdata(data)
#
SO.OilPrice(data)
checkdata(data)
