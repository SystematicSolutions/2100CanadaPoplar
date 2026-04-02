#
# Electric_NRCan_SmartGrid_Peak.jl
#
# Program: https://natural-resources.canada.ca/climate-change/green-infrastructure-programs/smart-grids/19793
#

using EnergyModel

module Electric_NRCan_SmartGrid_Peak

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
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

  ECCMap::VariableArray{2} = ReadDisk(db,"$Input/ECCMap") # [EC,ECC] # EC TO ECC Map
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Total Energy Demand (TBtu/Yr)
  xPkSav::VariableArray{4} = ReadDisk(db,"$Input/xPkSav") # [Enduse,EC,Area,Year] Peak Savings from Programs (MW)
  xPkSavECC::VariableArray{3} = ReadDisk(db,"SInput/xPkSavECC") # [ECC,Area,Year] Peak Savings from Programs (MW)

  # Scratch Variables
  TotDmd::VariableArray{2} = zeros(Float32,length(Tech),length(Area)) # [Tech,Area] Sector Enduse Demands (mmBTU/Yr)
  TotPkSav::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Sector Demand Reductions (MW)
end

function ResPolicy(db)
  data = RControl(; db)
  (; Input) = data
  (; Area,Areas,ECCMap,ECCs,ECs) = data 
  (; Enduses,Tech,Techs) = data
  (; TotDmd,TotPkSav,xDmd,xPkSav,xPkSavECC) = data

  # 
  # Enduse split based on demands in 2014
  #
  for area in Areas, tech in Techs    
    TotDmd[tech,area] = sum(xDmd[enduse,tech,ec,area,Yr(2014)] for enduse in Enduses,ec in ECs)
  end
  # 
  # Electric Peak Savings
  #  
  Electric = Select(Tech,"Electric")
  ON = Select(Area,"ON")
  TotPkSav[ON,Yr(2024):Yr(2026)] = [169,210,233]
  years = collect(Yr(2027):Final)
  for year in years
    TotPkSav[ON,year] = TotPkSav[ON,Yr(2026)]
  end

  # 
  # Allocate Demand Reduction to all Enduses
  #  
  years = collect(Future:Final)
  for enduse in Enduses, ec in ECs, year in years 
    xPkSav[enduse,ec,ON,year] = xPkSav[enduse,ec,ON,year]+TotPkSav[ON,year]* 
        xDmd[enduse,Electric,ec,ON,Yr(2014)]/TotDmd[Electric,ON]/1.04 
  end
    
  # 
  # Total across enduses
  #   
  years = collect(Future:Final)
  for year in years, ec in ECs, ecc in ECCs
    if ECCMap[ec,ecc] == 1
      xPkSavECC[ecc,ON,year] = sum(xPkSav[enduse,ec,ON,year] for enduse in Enduses)
    end
  end
      
  WriteDisk(db,"$Input/xPkSav",xPkSav)
  WriteDisk(db,"SInput/xPkSavECC",xPkSavECC)
end  #function ResPolicy

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
    ECCMap::VariableArray{2} = ReadDisk(db,"$Input/ECCMap") # [EC,ECC] # EC TO ECC Map
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demand (TBtu/Yr)
  xPkSav::VariableArray{4} = ReadDisk(db,"$Input/xPkSav") # [Enduse,EC,Area,Year] Peak Savings from Programs (MW)
  xPkSavECC::VariableArray{3} = ReadDisk(db,"SInput/xPkSavECC") # [ECC,Area,Year] Peak Savings from Programs (MW)

  # Scratch Variables
  TotDmd::VariableArray{2} = zeros(Float32,length(Tech),length(Area)) # [Tech,Area] Sector Enduse Demands (mmBTU/Yr)
  TotDmdz::VariableArray{3} = zeros(Float32,length(EC),length(Tech),length(Area)) # [EC,Tech,Area] Sector Enduse Demands (mmBTU/Yr)
  TotPkSav::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Sector Demand Reductions (MW)
  TotPkSavz::VariableArray{3} = zeros(Float32,length(EC),length(Area),length(Year)) # [EC,Area,Year] Sector Demand Reductions (MW)
end

function IndPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; Area,Areas,ECCMap,ECC,ECCs,EC,ECs) = data 
  (; Enduses,Nation,Tech,Techs) = data 
  (; ANMap,TotDmd,TotDmdz,TotPkSav,TotPkSavz,xDmd,xPkSav,xPkSavECC) = data

  # 
  # Enduse split based on demands in 2014
  #   
  TotDmd[Techs,Areas] = 
    sum(xDmd[eu,Techs,ec,Areas,Yr(2014)] for eu in Enduses, ec in ECs)

  # 
  # Electric Peak Savings
  #  
  Electric = Select(Tech,"Electric")
  ON = Select(Area,"ON")
  TotPkSav[ON,Yr(2024):Yr(2026)] = [99,123,136]

  years = collect(Yr(2027):Final)
  for year in years
    TotPkSav[ON,year] = TotPkSav[ON,year-1]
  end

  # 
  # Allocate Demand Reduction to all Enduses
  #  
  years = collect(Future:Final)
  for year in years, ec in ECs, enduse in Enduses
    xPkSav[enduse,ec,ON,year] = xPkSav[enduse,ec,ON,year]+TotPkSav[ON,year]* 
      xDmd[enduse,Electric,ec,ON,Yr(2014)]/TotDmd[Electric,ON]/1.04
  end

  # 
  # Total across enduses
  #   
  years = collect(Future:Final)
  for year in years, ec in ECs, ecc in ECCs
    if ECCMap[ec,ecc] == 1
      xPkSavECC[ecc,ON,year] = sum(xPkSav[enduse,ec,ON,year] for enduse in Enduses)
    end
   end

  #
  # Electric Peak Savings - Ontario, Petrochemicals
  #
  Petrochemicals = Select(EC,"Petrochemicals")
  for area in Areas
    TotDmdz[Petrochemicals,Electric,area] = sum(xDmd[enduse,Electric,Petrochemicals,area,Yr(2014)] for enduse in Enduses)
  end
*
  years = collect(Yr(2024):Yr(2026))
  for year in years
    TotPkSavz[Petrochemicals,ON,year] = 20
  end
  years = collect(Yr(2027):Final)
  for year in years
    TotPkSavz[Petrochemicals,ON,year] = TotPkSavz[Petrochemicals,ON,year-1]
  end

  #
  # Allocate Demand Reduction to all Enduses
  #
  years = collect(Future:Final)
  for year in years, enduse in Enduses
    xPkSav[enduse,Petrochemicals,ON,year] = xPkSav[enduse,Petrochemicals,ON,year]+TotPkSavz[Petrochemicals,ON,year]*
      xDmd[enduse,Electric,Petrochemicals,ON,Yr(2014)]/TotDmdz[Petrochemicals,Electric,ON]/1.04
  end
  #
  # Total across enduses
  #
  ecc = Select(ECC,"Petrochemicals")
  for year in years
    xPkSavECC[ecc,ON,year] = sum(xPkSav[enduse,Petrochemicals,ON,year] for enduse in Enduses)
  end

  #
  WriteDisk(db,"$Input/xPkSav",xPkSav)
  WriteDisk(db,"SInput/xPkSavECC",xPkSavECC)
end  #function IndPolicy

function PolicyControl(db)
  @info "Electric_NRCan_SmartGrid_Peak.jl - PolicyControl"
  ResPolicy(db)
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
