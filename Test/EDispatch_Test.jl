import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime
import EnergyModel: @finite_math, finite_inverse, finite_divide, finite_power
import EnergyModel: finite_exp, finite_log
import EnergyModel: checkdata, VariableArray, SetArray, Final, comparedata
import EnergyModel: unzip, E2020Folder

CTime = 2040
year = CTime - ITime + 1; current = year;
prior = max(year-1, 1); next = min(year+1, Final);

# Unzip StartBasePromula and BasePromula ---------------------------------------

db = M.DB
StartBasePromula_Folder = joinpath(E2020Folder, "StartBasePromula")
BasePromula_Folder = joinpath(E2020_older, "BasePromula")

db_sp = joinpath(StartBasePromula_Folder, "database.hdf5")
db_bp = joinpath(BasePromula_Folder, "database.hdf5")

fileloc = "2020Model\\StartBasePromula\\24.01.13 StartBasePromula.zip"
baseloc = "2020Model\\BasePromula\\24.01.13 BasePromula.zip"

# unzip databases into StartBase and Base subdirectories
# run(`wzunzip -d -o $fileloc $StartBasePromula_Folder`)
# run(`wzunzip -d -o $baseloc $BasePromula_Folder`)

# unzip StartBase dataframe into 2020Model 
unzip(fileloc)

# Test EDispatch ---------------------------------------------------------------

using DataFrames, DataFramesMeta
import EnergyModel.Engine.EDispatch as ED
# import EnergyModel.Engine.EDispatch as EDispatch
data = ED.Data(; db, year, prior, next, CTime);
data_sp = ED.Data(; db = db_sp, year, prior, next, CTime);
data_bp = ED.Data(; db = db_bp, year, prior, next, CTime);

checkdata(data)
checkdata(data_sp)
checkdata(data_bp)

df_sp = comparedata(data, data_sp)
@rsubset df_sp :Diff != 0
df_bp = comparedata(data, data_bp)
@rsubset df_bp :Diff != 0

# ED.InitializeDispatch(data);
ED.DispatchElectricity(data);


# units, UnitInSameEmissionGroup = ED.GetUnitsInSameEmissionGroup(data,node,EmissionGroupNumber)
# AgNum = ED.CreateNewAggUnit(data,node,AgNum)

checkdata(data)

df_sp2 = comparedata(data, data_sp) 
@rsubset df_sp2 :Diff != 0 
df_bp2 = comparedata(data, data_bp)
issues = @rsubset df_bp2 !isapprox(:Diff, 0)

name = "EGOutput/UnVCostUS"
df = ReadDisk(DataFrame, db, name)
df_sp = ReadDisk(DataFrame, db_sp, name)
df_bp = ReadDisk(DataFrame, db_bp, name)

data.UnEG[2,1,1]
@subset df :Year .== 2020
@subset df_bp :Year .== 2020

@rename! df :BJulia = :Value
@rename! df_sp :SPromula = :Value
@rename! df_bp :BPromula = :Value

df = DataFrame(JUnVCost = data.UnVCost[:,timep,month], 
BPUnVCost = data_bp.UnVCost[:,timep,month],
JFX = data.ExchangeRateUnit,
BPFX = data_bp.ExchangeRateUnit,
JVCostUS = data.UnVCostUS,
BPVCostUS = data_bp.UnVCostUS
)

@transform!(df, :BPRatio = :BPVCostUS ./ :BPUnVCost)
# Something is off between hdf5 files and dbas 
using Pkg
Pkg.add(url="https://github.com/AMD-SSI-Collaboration/PromulaDBA.jl")
Pkg.add(url="https://github.com/pnvolkmar/JuliaCompare.jl")

import JuliaCompare as J 
import PromulaDBA as P 

import JuliaCompare: db_files, Canada

df_diff = J.diff(df, df_bp)
@rsubset! df_diff :Diff != 0

J.plot_diff(df_diff; dim = "Month")

data.UnEG
data_bp.UnEG

# Looking at a specific unit ----------
unit = 532
(; MinBid,UnMustRun,UnVCost, UnArea, Area, GenCo, UnGenCo, Plant, UnPlant) = data;
(; Node, UnNode) = data;
UnMustRun[unit]
area = Select(Area, UnArea[unit])
genco = Select(GenCo, UnGenCo[unit])
plant = Select(Plant, UnPlant[unit])
node = Select(Node, UnNode[unit])

data_bp.UnAVCMonth[unit,month]*
data_bp.HDVCFr[plant,genco,node,timep,month]+
data_bp.UnPoTR[unit]*max(1-
data_bp.HDVCFr[plant,genco,node,timep,month],0)+(
data_bp.UnAFC[area]/(8760*.75)*1000)*
data_bp.HDFCFR[plant,genco,timep]


##

UnEGC=data.UnEGC
UnGC=data.UnGC
UnOURGC=data.UnOURGC
UnOR=data.UnOR
UnOOR=data.UnOOR
AvFactor=data.AvFactor
HDGCFR=data.HDGCFR

Unit=data.Unit
TimeP=data.TimeP
Month=data.Month
Area=data.Area
GenCo=data.GenCo
Node=data.Node
Plant=data.Plant

UnArea=data.UnArea
UnGenCo=data.UnGenCo
UnNode=data.UnNode
UnPlant=data.UnPlant


unit = 999
timep=Select(TimeP)
month=Select(Month)
area=Select(Area,UnArea[unit])
genco=Select(GenCo,UnGenCo[unit])
node=Select(Node,UnNode[unit])
plant=Select(Plant,UnPlant[unit])
UnPlant[unit]
UnArea[unit]




UnEGC[unit,timep,month]
UnGC[unit]
UnOURGC[unit]
UnOR[unit]
UnOOR[unit]
AvFactor[plant,timep,month,area]
HDGCFR[plant,genco,node,timep,month]

# UnGC is zero

CTime = 2019
year = CTime - ITime + 1; current = year;
prior = max(year-1, 1); next = min(year+1, Final);
