import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import EnergyModel: checkdata, VariableArray, SetArray

db = M.DB
year = 2020 - ITime + 1
current = 2020 - ITime + 1
prior = 2019 - ITime + 1
next = 2021 - ITime + 1

import EnergyModel.Engine.DirectAirCapture as DAC
data = DAC.Data(; db, year, current, prior, next);
#
checkdata(data)
#
DAC.SupplyDAC(data)
#
checkdata(data)
#
DAC.PriceDAC(data)
#
checkdata(data)
#
Nation=data.Nation
nations_a = Select(Nation, ["MX","ROW"]) # Works
nations_b = Select(Nation, !=(["MX","ROW"])) # Does not work, selects all
nations_c = Select(Nation, !=(["ROW"])) # Does not work, selects all
nations_d = Select(Nation, !=("ROW")) # Works

nations_e1 = Select(Nation, !=("MX")) # Works
nations_e2 = Select(Nation, !=("ROW")) # Works
nations_e = intersect(nations_e1,nations_e2) # Works

