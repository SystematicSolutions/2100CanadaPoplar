#
# Trans_Vol_Rail.jl
#
# An MOU was renewed between Transport Canada and the Railway Association of Canada December 2023.
# Class 1 railway intensity based 2030 targets provided by TC (Christian Martin and Jacob McBane).
# CPKC 38.3% emissions intensity reductions from 2020
# CN 43% emissions intensity reductions from 2019.
# Track share used to weight targets.
# Calculations reweighted for Ref25, 4.8% annual improvement through 2030. 
# Brock Batey - June 19, 2024.
#

using EnergyModel

module Trans_Vol_Rail

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Last,Future,DB,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TControl
  db::String
  
  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name
  FutureY=Future+1
  
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DEEBase::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/DEE") # [Enduse,Tech,EC,Area,Year] Device Efficiency in Base Case (Mile/mmBtu)
  DEMM::VariableArray{5} = ReadDisk(db,"$CalDB/DEMM") # [Enduse,Tech,EC,Area,Year] Maximum Device Efficiency Multiplier (Btu/Btu)
  DEStdP::VariableArray{5} = ReadDisk(db,"$Input/DEStdP") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards Policy (Btu/Btu)
 end

function TransPolicy(db)
  data = TControl(; db)
  (; CalDB,Input) = data
  (; Area,ECs,Enduse,Nation,Tech) = data
  (; ANMap,DEEBase,DEMM,DEStdP,FutureY) = data
  
  FutureY = Future+1
  
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  enduse = Select(Enduse,"Carriage")
  techs = Select(Tech,"TrainDiesel")

  for area in areas, ec in ECs, tech in techs
    DEStdP[enduse,tech,ec,area,Yr(2024)] = DEEBase[enduse,tech,ec,area,Last]*1.049
    DEStdP[enduse,tech,ec,area,Yr(2025)] = DEEBase[enduse,tech,ec,area,Last]*1.049*1.049
    DEStdP[enduse,tech,ec,area,Yr(2026)] = DEEBase[enduse,tech,ec,area,Last]*1.049*1.049*1.049
    DEStdP[enduse,tech,ec,area,Yr(2027)] = DEEBase[enduse,tech,ec,area,Last]*1.049*1.049*1.049*1.049
    DEStdP[enduse,tech,ec,area,Yr(2028)] = DEEBase[enduse,tech,ec,area,Last]*1.049*1.049*1.049*1.049*1.049
    DEStdP[enduse,tech,ec,area,Yr(2029)] = DEEBase[enduse,tech,ec,area,Last]*1.049*1.049*1.049*1.049*1.049*1.049
  end
  years = collect(Yr(2030):Final)
  for year in years, area in areas, ec in ECs, tech in techs
    DEStdP[enduse,tech,ec,area,year] = DEEBase[enduse,tech,ec,area,Last]*1.049*1.049*1.049*1.049*1.049*1.049*1.049
  end
  
  year = Future
  for area in areas, ec in ECs, tech in techs 
    @finite_math DEMM[enduse,tech,ec,area,year] = 
      DEMM[enduse,tech,ec,area,year-1]*DEStdP[enduse,tech,ec,area,year]/
        DEEBase[enduse,tech,ec,area,year-1]
  end
     
  years = collect(FutureY:Final)   
  for area in areas, ec in ECs, tech in techs, year in years   
    @finite_math DEMM[enduse,tech,ec,area,year] = 
      DEMM[enduse,tech,ec,area,year-1]*DEStdP[enduse,tech,ec,area,year]/
        DEStdP[enduse,tech,ec,area,year-1]
  end
      
  WriteDisk(db,"$Input/DEStdP",DEStdP)
  WriteDisk(db,"$CalDB/DEMM",DEMM) 
end

function PolicyControl(db)
  @info "Trans_Vol_Rail.jl - PolicyControl"
  TransPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
