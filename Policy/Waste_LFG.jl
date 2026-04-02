#
# Waste_LFG.jl - Regulations and other measures to reduce landfill methane emissions ($32.8M over 5 years)
#
# New regulations under the Canadian Environmental Protection Act (CEPA) to require the largest landfills 
# to assess methane emissions, install landfill methane recovery systems and monitor emissions on a regular basis. 
# Some provinces already have landfill methane capture regulations (British Columbia, Ontario and Quebec). 
# The new federal regulations would raise the level of performance across the country by setting requirements 
# in line with the most stringent North American regulations (British Columbia and California). 
# Landfills in all provinces would be implicated, with the majority in British Columbia, Alberta, Quebec and Ontario.
#
# MODEL VARIABLE             VDATA VARIABLE
#   CH4RecoveryFraction =      vCapture_Rate
#   CH4FlaringFraction =       vFlaring_Rate

using EnergyModel

module Waste_LFG

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: DB
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Waste::SetArray = ReadDisk(db,"MainDB/WasteKey")
  WasteDS::SetArray = ReadDisk(db,"MainDB/WasteDS")
  Wastes::Vector{Int} = collect(Select(Waste))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CH4RecoveryFraction::VariableArray{3} = ReadDisk(db,"MInput/CH4RecoveryFraction") # [Waste,Area,Year] CH4 Recovery Fraction (Tonnes/Tonnes)
end

function WastePolicy(db::String)
  data = MControl(; db)
  (; Area,AreaDS,Waste,WasteDS,Year) = data 
  (; Areas,Wastes,Years) = data
  (; CH4RecoveryFraction) = data

  #
  # Select policy areas and years
  #
  areas = Select(Area,["BC","AB","SK","MB","ON","QC","NB","NS","NL","PE","YT","NT"])
  years = collect(Yr(2028):Yr(2035))
  ashDry = Select(Waste,"AshDry")

  #
  # Set CH4RecoveryFraction data for AshDry waste type by area and year
  #
  # BC data
  BC = Select(Area,"BC")
  CH4RecoveryFraction[ashDry,BC,Yr(2028)] = 0.63
  CH4RecoveryFraction[ashDry,BC,Yr(2029)] = 0.64
  CH4RecoveryFraction[ashDry,BC,Yr(2030)] = 0.63
  CH4RecoveryFraction[ashDry,BC,Yr(2031)] = 0.63
  CH4RecoveryFraction[ashDry,BC,Yr(2032)] = 0.63
  CH4RecoveryFraction[ashDry,BC,Yr(2033)] = 0.63
  CH4RecoveryFraction[ashDry,BC,Yr(2034)] = 0.63
  CH4RecoveryFraction[ashDry,BC,Yr(2035)] = 0.68

  # AB data
  AB = Select(Area,"AB")
  CH4RecoveryFraction[ashDry,AB,Yr(2028)] = 0.25
  CH4RecoveryFraction[ashDry,AB,Yr(2029)] = 0.50
  CH4RecoveryFraction[ashDry,AB,Yr(2030)] = 0.50
  CH4RecoveryFraction[ashDry,AB,Yr(2031)] = 0.50
  CH4RecoveryFraction[ashDry,AB,Yr(2032)] = 0.50
  CH4RecoveryFraction[ashDry,AB,Yr(2033)] = 0.50
  CH4RecoveryFraction[ashDry,AB,Yr(2034)] = 0.50
  CH4RecoveryFraction[ashDry,AB,Yr(2035)] = 0.51

  # SK data
  SK = Select(Area,"SK")
  CH4RecoveryFraction[ashDry,SK,Yr(2028)] = 0.18
  CH4RecoveryFraction[ashDry,SK,Yr(2029)] = 0.34
  CH4RecoveryFraction[ashDry,SK,Yr(2030)] = 0.35
  CH4RecoveryFraction[ashDry,SK,Yr(2031)] = 0.35
  CH4RecoveryFraction[ashDry,SK,Yr(2032)] = 0.35
  CH4RecoveryFraction[ashDry,SK,Yr(2033)] = 0.35
  CH4RecoveryFraction[ashDry,SK,Yr(2034)] = 0.35
  CH4RecoveryFraction[ashDry,SK,Yr(2035)] = 0.39

  # MB data
  MB = Select(Area,"MB")
  CH4RecoveryFraction[ashDry,MB,Yr(2028)] = 0.31
  CH4RecoveryFraction[ashDry,MB,Yr(2029)] = 0.56
  CH4RecoveryFraction[ashDry,MB,Yr(2030)] = 0.56
  CH4RecoveryFraction[ashDry,MB,Yr(2031)] = 0.56
  CH4RecoveryFraction[ashDry,MB,Yr(2032)] = 0.56
  CH4RecoveryFraction[ashDry,MB,Yr(2033)] = 0.56
  CH4RecoveryFraction[ashDry,MB,Yr(2034)] = 0.56
  CH4RecoveryFraction[ashDry,MB,Yr(2035)] = 0.57
  

  # ON data
  ON = Select(Area,"ON")
  CH4RecoveryFraction[ashDry,ON,Yr(2028)] = 0.72
  CH4RecoveryFraction[ashDry,ON,Yr(2029)] = 0.73
  CH4RecoveryFraction[ashDry,ON,Yr(2030)] = 0.73
  CH4RecoveryFraction[ashDry,ON,Yr(2031)] = 0.73
  CH4RecoveryFraction[ashDry,ON,Yr(2032)] = 0.73
  CH4RecoveryFraction[ashDry,ON,Yr(2033)] = 0.73
  CH4RecoveryFraction[ashDry,ON,Yr(2034)] = 0.73
  CH4RecoveryFraction[ashDry,ON,Yr(2035)] = 0.74

  # QC data
  QC = Select(Area,"QC")
  CH4RecoveryFraction[ashDry,QC,Yr(2028)] = 0.66
  CH4RecoveryFraction[ashDry,QC,Yr(2029)] = 0.67
  CH4RecoveryFraction[ashDry,QC,Yr(2030)] = 0.67
  CH4RecoveryFraction[ashDry,QC,Yr(2031)] = 0.67
  CH4RecoveryFraction[ashDry,QC,Yr(2032)] = 0.67
  CH4RecoveryFraction[ashDry,QC,Yr(2033)] = 0.67
  CH4RecoveryFraction[ashDry,QC,Yr(2034)] = 0.67
  CH4RecoveryFraction[ashDry,QC,Yr(2035)] = 0.68
  
  # NB data
  NB = Select(Area,"NB")
  CH4RecoveryFraction[ashDry,NB,Yr(2028)] = 0.60
  CH4RecoveryFraction[ashDry,NB,Yr(2029)] = 0.68
  CH4RecoveryFraction[ashDry,NB,Yr(2030)] = 0.68
  CH4RecoveryFraction[ashDry,NB,Yr(2031)] = 0.68
  CH4RecoveryFraction[ashDry,NB,Yr(2032)] = 0.68
  CH4RecoveryFraction[ashDry,NB,Yr(2033)] = 0.68
  CH4RecoveryFraction[ashDry,NB,Yr(2034)] = 0.68
  CH4RecoveryFraction[ashDry,NB,Yr(2035)] = 0.68

  # NS data
  NS = Select(Area,"NS")
  CH4RecoveryFraction[ashDry,NS,Yr(2028)] = 0.31
  CH4RecoveryFraction[ashDry,NS,Yr(2029)] = 0.58
  CH4RecoveryFraction[ashDry,NS,Yr(2030)] = 0.62
  CH4RecoveryFraction[ashDry,NS,Yr(2031)] = 0.62
  CH4RecoveryFraction[ashDry,NS,Yr(2032)] = 0.62
  CH4RecoveryFraction[ashDry,NS,Yr(2033)] = 0.62
  CH4RecoveryFraction[ashDry,NS,Yr(2034)] = 0.62
  CH4RecoveryFraction[ashDry,NS,Yr(2035)] = 0.68

  # NL data
  NL = Select(Area,"NL")
  CH4RecoveryFraction[ashDry,NL,Yr(2028)] = 0.45
  CH4RecoveryFraction[ashDry,NL,Yr(2029)] = 0.55
  CH4RecoveryFraction[ashDry,NL,Yr(2030)] = 0.55
  CH4RecoveryFraction[ashDry,NL,Yr(2031)] = 0.55
  CH4RecoveryFraction[ashDry,NL,Yr(2032)] = 0.55
  CH4RecoveryFraction[ashDry,NL,Yr(2033)] = 0.55
  CH4RecoveryFraction[ashDry,NL,Yr(2034)] = 0.55
  CH4RecoveryFraction[ashDry,NL,Yr(2035)] = 0.55

  # PE data
  PE = Select(Area,"PE")
  CH4RecoveryFraction[ashDry,PE,Yr(2028)] = 0.00
  CH4RecoveryFraction[ashDry,PE,Yr(2029)] = 0.75
  CH4RecoveryFraction[ashDry,PE,Yr(2030)] = 0.75
  CH4RecoveryFraction[ashDry,PE,Yr(2031)] = 0.75
  CH4RecoveryFraction[ashDry,PE,Yr(2032)] = 0.75
  CH4RecoveryFraction[ashDry,PE,Yr(2033)] = 0.75
  CH4RecoveryFraction[ashDry,PE,Yr(2034)] = 0.75
  CH4RecoveryFraction[ashDry,PE,Yr(2035)] = 0.75

  # YT data
  YT = Select(Area,"YT")
  CH4RecoveryFraction[ashDry,YT,Yr(2028)] = 0.00
  CH4RecoveryFraction[ashDry,YT,Yr(2029)] = 0.00
  CH4RecoveryFraction[ashDry,YT,Yr(2030)] = 0.00
  CH4RecoveryFraction[ashDry,YT,Yr(2031)] = 0.00
  CH4RecoveryFraction[ashDry,YT,Yr(2032)] = 0.00
  CH4RecoveryFraction[ashDry,YT,Yr(2033)] = 0.00
  CH4RecoveryFraction[ashDry,YT,Yr(2034)] = 0.00
  CH4RecoveryFraction[ashDry,YT,Yr(2035)] = 0.45

  # NT data
  NT = Select(Area,"NT")
  CH4RecoveryFraction[ashDry,NT,Yr(2028)] = 0.00
  CH4RecoveryFraction[ashDry,NT,Yr(2029)] = 0.42
  CH4RecoveryFraction[ashDry,NT,Yr(2030)] = 0.42
  CH4RecoveryFraction[ashDry,NT,Yr(2031)] = 0.42
  CH4RecoveryFraction[ashDry,NT,Yr(2032)] = 0.42
  CH4RecoveryFraction[ashDry,NT,Yr(2033)] = 0.42
  CH4RecoveryFraction[ashDry,NT,Yr(2034)] = 0.42
  CH4RecoveryFraction[ashDry,NT,Yr(2035)] = 0.42

  #
  # Apply AshDry values to all other waste types (except wood wastes)
  #
  wood_wastes = Select(Waste,["WoodWastePulpPaper","WoodWasteSolidWood"])
  other_wastes = setdiff(Wastes,wood_wastes)
  
  for waste in other_wastes, area in areas, year in years
    if waste != ashDry
      CH4RecoveryFraction[waste,area,year] = CH4RecoveryFraction[ashDry,area,year]
    end
  end

  #
  # Extend values from 2035 to Final year
  #
  years = collect(Yr(2036):Final)
  for waste in other_wastes, area in areas, year in years
    CH4RecoveryFraction[waste,area,year] = CH4RecoveryFraction[waste,area,Yr(2035)]
  end

  WriteDisk(db,"MInput/CH4RecoveryFraction",CH4RecoveryFraction)

  #@info "Waste_LFG.jl - PolicyControl completed"
end

function PolicyControl(db)
  @info "Waste_LFG.jl - PolicyControl"
  WastePolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
