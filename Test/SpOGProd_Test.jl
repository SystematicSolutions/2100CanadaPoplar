import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import EnergyModel: VariableArray, SetArray, checkdata, unzip

db = M.DB
year = 2020 - ITime + 1
prior = 2019 - ITime + 1
next = 2021 - ITime + 1
CTime = 2020

unzip("2020Model/BasePromula/23.11.23 BasePromula.zip")

import EnergyModel.Engine.SpOGProd as SOG
data = SOG.Data(; db=db, year=year, prior=prior, next=next, CTime=CTime);

checkdata(data)

#
SOG.Control(data);
checkdata(data);
#
