#
# E2020OMExpenditures.jl
#
using EnergyModel

module E2020OMExpenditures

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMDS::SetArray = ReadDisk(db,"KInput/ECCTOMDS")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  ToTOMVariable::SetArray = ReadDisk(db,"KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  OMExp::VariableArray{3} = ReadDisk(db,"SOutput/OMExp") # [ECC,Area,Year] O&M Expenditures (M$)
  OMExpE::VariableArray{3} = ReadDisk(db,"KOutput/OMExpE") # [ECCTOM,AreaTOM,Year] O&M Expenditures (M$) from ENERGY 2020 (2017 M$)
  SplitECCtoTOM::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOM") # [ECC,ECCTOM,AreaTOM,Year] Split ECC into ECCTOM ($/$)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  OMExpArea::VariableArray{3} = zeros(Float32,length(ECCTOM),length(Area),length(Year)) # [ECCTOM,Area,Year] O&M Expenditures (M$) from ENERGY 2020 (2017 M$)
end

function OMExpenditures(data)
  (; db) = data
  (; Area,AreaTOM,AreaTOMs,Areas,ECC,ECCs,Nation) = data
  (; ECCTOMs,ToTOMVariable,Years) = data
  (; ANMap,MapAreaTOM,MapAreaTOMNation,IsActiveToECCTOM,OMExp,OMExpArea,OMExpE) = data
  (; SplitECCtoTOM,TOMBaseYear,xInflation) = data
  
  totomvariable = Select(ToTOMVariable,"OMExpE")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)

  for year in Years, areatom in AreaTOMs, ecctom in ecctoms
    area = Select(Area,AreaTOM[areatom])
    OMExpArea[ecctom,area,year] = sum(OMExp[ecc,area,year]/
      xInflation[area,year]*xInflation[area,TOMBaseYear]*
        SplitECCtoTOM[ecc,ecctom,areatom,year] for ecc in ECCs)
  end

  for year in Years, areatom in AreaTOMs, ecctom in ecctoms
    OMExpE[ecctom,areatom,year] = sum(OMExpArea[ecctom,area,year]*
      MapAreaTOM[area,areatom] for area in Areas)
  end

  WriteDisk(db,"KOutput/OMExpE",OMExpE)

end

function CalcExpenditures(db)
  data = MControl(; db)
  (; Area,AreaTOM,Areas,ECC,Years) = data
  (; OMExpArea) = data

  OMExpenditures(data)
end

function Control(db)
  @info "E2020OMExpenditures.jl - Control"
  CalcExpenditures(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
