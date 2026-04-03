import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import EnergyModel: checkdata

CTime = 2042
year = CTime - ITime + 1; current = year;
prior = max(year-1, 1); next = min(year+1, Final);
db = M.DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

import EnergyModel.Engine.ECosts as ELC
fileloc = "2020Model\\StartBasePromula\\23.11.23 StartBasePromula.zip"

run(`wzunzip -d -o $fileloc 2020Model`)

data = ELC.Data(; db, year, prior, next, CTime);
checkdata(data)

ELC.Costs(data);
checkdata(data)

(;UnFlFr,UnFlFrMSF,UnFlFrTotal) = data;

(; UnSLDPR, UnNA, DPRSL) = data;
(; UnArea, Area, UnPlant) = data;

unit=135
UnArea[unit]
area = Select(Area,UnArea[unit])
UnPlant[unit]
UnSLDPR[unit]
DPRSL[area]
UnNA[unit]

