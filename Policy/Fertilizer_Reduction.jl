#
# Fertilizer_Reduction.jl
# this policy file now reflects the estimated 2030 impact of Agriculture programs on fertilizer N2O emissions.
#
# according to CEEMA_Ag_Emissions_2025.xlsx, Crop production N2O emissions will be 18.532 Mt CO2e.
#
# according to Ag Measures Revised Estimates 2025.docx, total 2030 reductions in fertilizer emissions
# will be 0.31 Mt CO2e.
#
# this is 1.673 % reduction (or a factor of 0.01673).
#
# this is assumed to scale up starting in 2027 and reaching full reduction in 2030.
#
# reductions are assumed to continue to 2050.
#
using EnergyModel

module Fertilizer_Reduction

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Process Pollution (Tonnes/Yr)

  # Scratch Variables
  FertilizerPercent::VariableArray{1} = zeros(Float32,length(Area)) # Percentage of N20 Crop emission that are to be reduced
  FertilizerTarget::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # ramping up of reductions starting in 2027 and reaching full amount in 2030

end

function MacroPolicy(db)
  data = MControl(; db)
  (;Area,ECC,Poll) = data
  (;xMEPol) = data
  (;FertilizerPercent,FertilizerTarget) = data
  
  areas =  Select(Area,["BC","AB","SK","MB","ON","QC","NB","NS","PE","NL"])
  poll = Select(Poll,"N2O")
  ecc = Select(ECC,"CropProduction")
  
  FertilizerPercent[areas] .= [
                               0.01673  #BC
                               0.01673  #AB
                               0.01673  #SK
                               0.01673  #MB
                               0.01673  #ON
                               0.01673  #QC
                               0.01673  #NB
                               0.01673  #NS
                               0.01673  #PE
                               0.01673  #NL
                              ]

  years = collect(Yr(2026):Yr(2030))
  FertilizerTarget[areas,years] .= [
                                     # 2026   2027   2028   2029   2030  Area 
                                       0.00   0.25   0.50   0.75   1.00  #BC 
                                       0.00   0.25   0.50   0.75   1.00  #AB
                                       0.00   0.25   0.50   0.75   1.00  #SK
                                       0.00   0.25   0.50   0.75   1.00  #MB
                                       0.00   0.25   0.50   0.75   1.00  #ON
                                       0.00   0.25   0.50   0.75   1.00  #QC
                                       0.00   0.25   0.50   0.75   1.00  #NB
                                       0.00   0.25   0.50   0.75   1.00  #NS
                                       0.00   0.25   0.50   0.75   1.00  #PE
                                       0.00   0.25   0.50   0.75   1.00  #NL
                                  ]
  for year in years, area in areas
    xMEPol[ecc,poll,area,year] = xMEPol[ecc,poll,area,year]-xMEPol[ecc,poll,area,year]*
                                 FertilizerPercent[area]*FertilizerTarget[area,year]
  end

  years = collect(Yr(2031):Yr(2050))
  for year in years, area in areas
    xMEPol[ecc,poll,area,year] = xMEPol[ecc,poll,area,Yr(2030)]
  end

  WriteDisk(db,"SInput/xMEPol",xMEPol)

end

function PolicyControl(db)
  @info("Fertilizer_Reduction.jl PolicyControl")
  MacroPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
