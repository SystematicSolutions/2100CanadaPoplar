#
# AdjustForestry_TOM.jl
#
using EnergyModel

module AdjustForestry_TOM

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ICalib
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  MacroSwitch::SetArray = ReadDisk(db,"MInput/MacroSwitch") # [Nation] String Indicator of Macroeconomic Forecast (TOM,Stokes,AEO,CER)
  PCCN::VariableArray{4} = ReadDisk(db,"$Outpt/PCCN") # [Enduse,Tech,EC,Area] Normalized Process Capital Cost ($/mmBtu)
  PCTC::VariableArray{5} = ReadDisk(db,"$Outpt/PCTC") # [Enduse,Tech,EC,Area,Year] Process Capital Cap. Trade Off Coef. (DLESS)
  PEM::VariableArray{3} = ReadDisk(db,"$CalDB/PEM") # Maximum Process Efficiency ($/Btu) [Enduse,EC,Area]
  PFPN::VariableArray{4} = ReadDisk(db,"$Outpt/PFPN") # [Enduse,Tech,EC,Area] Process Normalized Fuel Price ($/mmBtu)
  PFTC::VariableArray{5} = ReadDisk(db,"$Outpt/PFTC") # [Enduse,Tech,EC,Area,Year] Process Fuel Trade Off Coefficient
  POCF::VariableArray{4} = ReadDisk(db,"$CalDB/POCF") # [Enduse,Tech,EC,Area] Process Operating Cost Fraction
  RPCTC::VariableArray{5} = ReadDisk(db,"$Outpt/RPCTC") # [Enduse,Tech,EC,Area,Year] Retrofit Process Capital Trade Off Coefficient (DLESS)
  RPFTC::VariableArray{5} = ReadDisk(db,"$Outpt/RPFTC") # [Enduse,Tech,EC,Area,Year] Retrofit Process Fuel Trade Off Coefficient

  # Scratch Variables
 # AreaToUse     'Area To Use to Fill in Values'
end

function SetPCTC(data,SelectArea,TargetArea, ec)
  (;db, Outpt, CalDB) = data
  (;Techs,Enduses) = data
  (;Years) = data
  (;PCCN,PCTC,PEM,PFPN,PFTC,POCF,RPCTC,RPFTC) = data
  
  for area in TargetArea

    for tech in Techs, enduse in Enduses
      PCCN[enduse,tech,ec,area] = PCCN[enduse,tech,ec,SelectArea]
    end
    for year in Years, tech in Techs, enduse in Enduses
      PCTC[enduse,tech,ec,area,year] = PCTC[enduse,tech,ec,SelectArea,year]
    end
    for enduse in Enduses
      PEM[enduse,ec,area] = PEM[enduse,ec,SelectArea]
    end
    for tech in Techs, enduse in Enduses
      POCF[enduse,tech,ec,area] = POCF[enduse,tech,ec,SelectArea]
    end
    for tech in Techs, enduse in Enduses
      PFPN[enduse,tech,ec,area] = PFPN[enduse,tech,ec,SelectArea]
    end
    for year in Years, tech in Techs, enduse in Enduses
      PFTC[enduse,tech,ec,area,year] = PFTC[enduse,tech,ec,SelectArea,year]
    end
    for year in Years, tech in Techs, enduse in Enduses
      RPCTC[enduse,tech,ec,area,year] = RPCTC[enduse,tech,ec,SelectArea,year]
    end
    for year in Years, tech in Techs, enduse in Enduses
      RPFTC[enduse,tech,ec,area,year] = RPFTC[enduse,tech,ec,SelectArea,year]
    end
  end
  
  WriteDisk(db,"$Outpt/PCCN",PCCN)
  WriteDisk(db,"$Outpt/PCTC",PCTC)
  WriteDisk(db,"$CalDB/PEM",PEM)
  WriteDisk(db,"$CalDB/POCF",POCF)
  WriteDisk(db,"$Outpt/PFPN",PFPN)
  WriteDisk(db,"$Outpt/PFTC",PFTC)
  WriteDisk(db,"$Outpt/RPCTC",RPCTC)
  WriteDisk(db,"$Outpt/RPFTC",RPFTC)

end

function ICalibration(db)
  data = ICalib(; db)
  (;Area,EC,Nation) = data
  (;Tech) = data
  (;MacroSwitch) = data
  
  #
  # California and Mountain Solar use Pacific
  #
  
  CN = Select(Nation,"CN")
  if MacroSwitch[CN] == "TOM"
    Pac = Select(Area,"Pac")
    target_areas = Select(Area,["CA","Mtn"])
    Forestry = Select(EC,"Forestry")
    SetPCTC(data,Pac,target_areas,Forestry)
    
  end
  
end

function CalibrationControl(db)
  @info "AdjustForestry_TOM.jl - CalibrationControl"

  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
