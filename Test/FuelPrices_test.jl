import EnergyModel as M

import .M: ReadDisk, WriteDisk, Select, MaxTime, HisTime, finite_inverse
import .M: VariableArray, SetArray

import .M.Outputs.FuelPrices as FP

data = FP.Data(; db = M.DB);

db = M.DB
SceName = "Test"
es = area = a = 1
FP.DtaRunSupply(data, a, es, SceName)

FP.Control(db, SceName)

ESDS = ReadDisk(db, "MainDB/ESDS")
