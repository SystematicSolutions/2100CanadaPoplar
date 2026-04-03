import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime,Final
import EnergyModel: @finite_math, finite_inverse, finite_divide, finite_power
import EnergyModel: VariableArray, SetArray, checkdata, unzip, finite_exp, finite_log
import EnergyModel: Select, Yr
using DataFrames, DataFramesMeta
import EnergyModel.Engine.EPollution as EP

db = M.DB
CTime = 2027
year = CTime - ITime + 1
prior = max(1, year-1)
next = min(year+1,Final)

data = EP.Data(; db, year, prior, next, CTime);

(; Area, Unit, Plant, Poll, FuelEP, ECC, Year)  = data;
UnFlFr::VariableArray{3} = ReadDisk(db,"EGOutput/UnFlFr"); #[Unit,FuelEP,Year]  Fuel Fraction (Btu/Btu)
uncode = "QC06100000050"
UnCode = ReadDisk(db,"EGInput/UnCode"); #[Unit,Year]  Unit Code
unit = findall(UnCode .== uncode)
fuelep = Select(FuelEP, "PetroCoke")
year = collect(Yr(2026):Yr(2030))
push!(year, Yr(2050))
Symbol.(Year[year])
present = DataFrame(dropdims(UnFlFr[unit,:,year], dims = 1), Symbol.(Year[year]))
present.FuelEP = FuelEP
select!(present, "FuelEP", Not("FuelEP"))

(; EuFPol) = data;
area = Select(Area, "")
units = Select(UnArea, ==("ON"))
fuelep = Select(FuelEP, "Biomass")
poll = Select(Poll, "NOX")

sum(UnPolGross[units,fuelep,poll])
ecc = Select(ECC, "UtilityGen")
area = Select(Area, "ON")
EuFPol[fuelep,ecc,poll,area]

using DataFrames, DataFramesMeta
unpolgross = DataFrame(Unit = units, UnPolGross = UnPolGross[units,fuelep,poll])
@rsubset unpolgross :UnPolGross != 0

test = ReadDisk(db,"SOutput/EuFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Energy Pollution with Cogeneration (Tonnes/Yr)
sum(test)
sum(test[fuelep,:,:,:])

checkdata(data)
EP.InitializePollution(data);
checkdata(data)
EP.Part1(data);
checkdata(data)
#
EP.Part2(data);
checkdata(data)
#
