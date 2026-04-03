#
# CogenerationCapitalCost.jl
#
using EnergyModel

module CogenerationCapitalCost

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CgCC::VariableArray{4} = ReadDisk(db,"$Input/CgCC") # [Tech,EC,Area,Year] Cogeneration Capital Cost (Real $/mmBtu/Yr)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Areas,ECs,Tech,Techs,Years) = data
  (;CgCC,xExchangeRate,xInflation) = data
 
 for year in Years, area in Areas, ec in ECs, tech in Techs
  CgCC[tech,ec,area,year] = 0
 end

  #
  # Assume input value is in 1985 US$ - Ian 02/25/22
  #
  solar = Select(Tech,"Solar")
  for ec in ECs, area in Areas, year in Years 
    CgCC[solar,ec,area,year] = 20 * xExchangeRate[area,Yr(1985)] / xInflation[area,Yr(1985)]
  end

  WriteDisk(db,"$Input/CgCC",CgCC)

end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CgCC::VariableArray{4} = ReadDisk(db,"$Input/CgCC") # [Tech,EC,Area,Year] Cogeneration Capital Cost ($/mmBtu/Yr)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Areas,ECs,Techs,Years) = data
  (;CgCC,xExchangeRate,xInflation) = data
  
  #
  # These values are for Textiles from ARC 80. 
  # J. Amlin 8/13/02
  #
  #/           Gas   Oil   Coal Biomass Electric  Sol   LPG  Stm  Geo HPump DPump Hydro
  #Textiles   9.20  9.20   9.20   9.20     9.20  9.20  9.20 9.20 9.20  9.20  9.20 9.2

  for tech in Techs  
    CgCC[tech,1,1,Zero] = 9.20
  end  
  
  #
  # Covert from 1975 US$ to 1985 US$ (1975 to 1985 inflation is 1.99).
  #
  
  for tech in Techs
    CgCC[tech,1,1,Zero] = CgCC[tech,1,1,Zero] * 1.99 
  end
  
  for tech in Techs
    CgCC[tech,1,1,Zero] = CgCC[tech,1,1,Zero] * xExchangeRate[1,Yr(1985)] / xInflation[1,Yr(1985)]
  end
  
  #
  # Map to all ECs, Areas, and Years
  #
  
  for year in Years, area in Areas, ec in ECs, tech in Techs
    CgCC[tech,ec,area,year] = CgCC[tech,1,1,Zero]
  end
  
  WriteDisk(db,"$Input/CgCC",CgCC)

end

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CgCC::VariableArray{4} = ReadDisk(db,"$Input/CgCC") # [Tech,EC,Area,Year] Cogeneration Capital Cost (Real $/mmBtu/Yr)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  CgCapCost75::VariableArray{2} = zeros(Float32,length(EC),length(Tech)) # [Tech,EC] Cogeneration Capital Cost (1975 US$/mmBtu/Yr)
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Areas,EC,ECs,Techs,Years) = data
  (;CgCC,xExchangeRate,xInflation) = data
  (;CgCapCost75) = data

  for year in Years, area in Areas, ec in ECs, tech in Techs
    CgCC[tech,ec,area,year] = 0
  end

  #
  # Source: ARC 80 - P. Cross 7/18/94
  # Make Industrial Gas, Other Basic Chemicals, and Fertilizer equal to Petrochemicals.
  # T. Harger 10/4/2007
  #
  ecs = Select(EC,["Textiles","PulpPaperMills","Petrochemicals","IndustrialGas",
                   "OtherChemicals","Fertilizer","IronSteel","Aluminum"])
  CgCapCost75[ecs,Techs] .= [
  #/              Gas   Oil  Coal Biomass Electric Solar   LPG OffRoad HeatPump Steam FuelCell Storage
  #=Textiles=#   9.20  9.20  9.20    9.20     9.20  9.20  9.20    9.20     9.20  9.20     9.20    9.20
  #=PulpPaper=#  4.18  4.18  4.18    4.18     4.18  4.18  4.18    4.18     4.18  4.18     4.18    4.18
  #=PetroChem=#  3.35  3.35  3.35    3.35     3.35  3.35  3.35    3.35     3.35  3.35     3.35    3.35
  #=IndGas=#     3.35  3.35  3.35    3.35     3.35  3.35  3.35    3.35     3.35  3.35     3.35    3.35
  #=OtherChem=#  3.35  3.35  3.35    3.35     3.35  3.35  3.35    3.35     3.35  3.35     3.35    3.35
  #=Fertilzer=#  3.35  3.35  3.35    3.35     3.35  3.35  3.35    3.35     3.35  3.35     3.35    3.35
  #=IronSteel=#  4.18  4.18  4.18    4.18     4.18  4.18  4.18    4.18     4.18  4.18     4.18    4.18
  #=Nonferous=#  4.18  4.18  4.18    4.18     4.18  4.18  4.18    4.18     4.18  4.18     4.18    4.18
  ]


  #
  # 1975 to 1985 Inflation is 1.99
  #
  for tech in Techs, ec in ecs, area in Areas, year in Years 
    CgCC[tech,ec,area,year] = CgCapCost75[ec,tech] * 1.99 * xExchangeRate[area,Yr(1985)] / 
                              xInflation[area,Yr(1985)]
  end
  
  #
  # Fill-in Missing Values
  #
  Textiles = Select(EC,"Textiles")
  for ec in ECs
    if CgCC[1,ec,1,1] == 0
      for year in Years, area in Areas, tech in Techs
        CgCC[tech,ec,area,year] = CgCC[tech,Textiles,area,year]
      end
    end
  end

  WriteDisk(db,"$Input/CgCC",CgCC)

end

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CgCC::VariableArray{4} = ReadDisk(db,"$Input/CgCC") # [Tech,EC,Area,Year] Cogeneration Capital Cost ($/mmBtu/Yr)

  # Scratch Variables
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Techs,Areas,Years,ECs,Techs) = data
  (;CgCC) = data

  #
  # 1. This data is from ARC 80.
  # 2. This could include Hybrids which generate excess power
  # 3. G.backus
  #
  
  for year in Years, area in Areas, ec in ECs, tech in Techs
    CgCC[tech,ec,area,year] = 0
  end

  WriteDisk(db,"$Input/CgCC",CgCC)
  
end

function CalibrationControl(db)
  @info "CogenerationCapitalCost.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
