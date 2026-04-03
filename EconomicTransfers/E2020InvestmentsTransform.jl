#
# E2020InvestmentsTransform.jl
#
using EnergyModel

module E2020InvestmentsTransform

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
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  ToTOMVariable::SetArray = ReadDisk(db,"KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  IFC::VariableArray{3} = ReadDisk(db,"KOutput/IFC") # [ECCTOM,AreaTOM,Year] Construction Investments (2017 $M/Yr)
  IFCinto::VariableArray{3} = ReadDisk(db,"KOutput/IFCinto") # [ECCTOM,AreaTOM,Year] Construction Investments (2017 $M/Yr)
  IFME::VariableArray{3} = ReadDisk(db,"KOutput/IFME") # [ECCTOM,AreaTOM,Year]  Investments in Machinery & Equipment (2017 $M/Yr)
  IFMEinto::VariableArray{3} = ReadDisk(db,"KOutput/IFMEinto") # [ECCTOM,AreaTOM,Year]  Investments in Machinery & Equipment  (2017 $M/Yr)
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"

  #
  # Scratch Variables
  #
  IFCintoTot::VariableArray{2} = zeros(Float32,length(AreaTOM),length(Year)) # [AreaTOM,Year] Total Construction Investments (2017 $M/Yr)
  IFMEintoTot::VariableArray{2} = zeros(Float32,length(AreaTOM),length(Year)) # [AreaTOM,Year] Total Investments in Machinery & Equipment  (2017 $M/Yr)

end

function InvestmentsintoTOM(db)
  data = MControl(; db)
  (; AreaTOMs,ECCTOMs,ToTOMVariable,Years) = data
  (; IFC,IFCinto,IFMEinto,IFME,IsActiveToECCTOM) = data

  totomvariable = Select(ToTOMVariable,"DefaultintoTOM")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)

  for year in Years, areatom in AreaTOMs, ecctom in ecctoms
    IFCinto[ecctom,areatom,year] = IFC[ecctom,areatom,year]
    IFMEinto[ecctom,areatom,year] = IFME[ecctom,areatom,year]
  end

  WriteDisk(db,"KOutput/IFCinto",IFCinto)
  WriteDisk(db,"KOutput/IFMEinto",IFMEinto)
end # InvestmentsintoTOM

#
########################
#
function Control(db)
    @info "E2020InvestmentsTransform.jl - Control"
    InvestmentsintoTOM(db)
  end

  if abspath(PROGRAM_FILE) == @__FILE__
    Control(DB)
  end

  end

