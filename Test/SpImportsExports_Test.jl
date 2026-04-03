import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import EnergyModel: VariableArray, SetArray, checkdata, unzip

db = M.DB
year = 2020 - ITime + 1
# current = 2020 - ITime + 1
prior = 2019 - ITime + 1
next = 2021 - ITime + 1

import EnergyModel.Engine.SpImportsExports as SIE
unzip("2020Model/StartBasePromula/23.11.23 StartBasePromula.zip")

data = SIE.Data(; db=db, year=year, prior=prior, next=next);
checkdata(data)
#
SIE.Control(data)
checkdata(data)
#

(; Outflow, SurplusArea) = data;

using DataFrames, DataFramesMeta
df = ReadDisk(DataFrame, db, "SpOutput/SurplusArea")
@subset!(df, :Year .== 2020)
@subset!(df, isnan.(:Value))
