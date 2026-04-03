using Revise
import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import EnergyModel: VariableArray, SetArray, checkdata, unzip, Final

db = M.DB
CTime = 2022
year = CTime - ITime + 1
prior = max(year - 1, 1)
next = min(year + 1, Final)

import EnergyModel.Engine.SpGas as SG

data = SG.Data(; db=db, year=year, prior=prior, next=next, CTime=CTime);
(; GDemand,Imports) = data;
(; FuelEP) = data;
fep_ng = Select(FuelEP, "NaturalGas");
GDemand
Imports[fep_ng, :]
checkdata(data)
#
SG.Control(data);
checkdata(data)
#
SG.GasDeliveredPrices(data);
checkdata(data)
#
SG.GasPrice(data)
checkdata(data)
#
