import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import EnergyModel: VariableArray, SetArray, unzip, checkdata

db = M.DB
year = 2020 - ITime + 1
prior = 2019 - ITime + 1
next = 2021 - ITime + 1
CTime = 2020

unzip("2020Model/BasePromula/23.11.23 BasePromula.zip")
import EnergyModel.Engine.SpHydrogen as SH
data = SH.Data(; db, year, prior, next, CTime);

checkdata(data)
# EISector has NaNs
# EuDemand has NaNs
# LDCECC has NaNs
# SaEC has NaNs
data = M.removedatanans(data);
checkdata(data)
SH.SupplyHydrogen(data);
checkdata(data)
#

# CgCap has NaNs
# CgGen has NaNs
# CgInv has NaNs
# EuFPol has NaNs
# EuPol has NaNs
# EuDemand has NaNs
# Exports has NaNs
# FsDemand has NaNs
# FuelExpenditures has NaNs
# H2CUF has NaNs
# H2Cap has NaNs
# H2CapCR has NaNs
# H2CapI has NaNs
# H2CapRR has NaNs
# H2Demand has NaNs
# H2Dmd has NaNs
# H2Exports has NaNs
# H2FsDem has NaNs
# H2FsPol has NaNs
# H2FsReq has NaNs
# H2Imports has NaNs
# H2Pol has NaNs
# H2Prod has NaNs
# H2ProdNation has NaNs
# H2Production has NaNs
# H2SaEC has NaNs
# H2SqDemand has NaNs
# H2SqPol has NaNs
# H2SqPolPenalty has NaNs
# Imports has NaNs
# LDCECC has NaNs
# NcFPol has NaNs
# NcPol has NaNs
# NH3Cap has NaNs
# NH3CapCR has NaNs
# NH3CapI has NaNs
# NH3CapRR has NaNs
# NH3CUF has NaNs
# NH3Exports has NaNs
# NH3Imports has NaNs
# NH3Prod has NaNs
# NH3ProdNation has NaNs
# NH3Production has NaNs
# OMExp has NaNs
# PInv has NaNs
# POMExp has NaNs
# SaEC has NaNs
# SqPolCCNet has NaNs
# SqPolPenalty has NaNs
# TotDemand has NaNs
# H2CapAvailable has NaNs
# H2CapTotal has NaNs
# H2SqDmd has NaNs
# H2SqDmdFuelEP has NaNs
# NH3CapAvailable has NaNs
# NH3CapTotal has NaNs

sum(isnan.(data.H2CapRR))

