#
# PCF_DeviceStd_Res.jl
#
# This policy simulates the portion of the NRCan Strategy for Energy Efficient Buildings 
# related to equipments in the residential and commercial sectors. It increases the Device efficiency standard 
# (DEStdP) until we reach the goal of reducing energy demand by 18.1 PJ in 2030 in the 
# residential sector and 21 PJ in the commercial sector (A. Dumas 2019/11/18).
#
# Details about the underlying assumptions for this policy are available in the following file:
# \\ncr.int.ec.gc.ca\shares\e\ECOMOD\Documentation\Policy - Buildings Policies.docx.
#
########################

using EnergyModel

module PCF_DeviceStd_Res

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
  DCCLimit::VariableArray{5} = ReadDisk(db,"$Input/DCCLimit") # [Enduse,Tech,EC,Area,Year] Device Capital Cost Limit Multiplier ($/$)
  DEERef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/DEE") # Device Efficiency in Reference Case (Btu/Btu) [Enduse,Tech,EC,Area]
  DEE::VariableArray{5} = ReadDisk(db,"$Outpt/DEE") # [Enduse,Tech,EC,Area,Year] Device Efficiency (Btu/Btu)
  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area,Year] Maximum Device Efficiency (Btu/Btu)
  DEMM::VariableArray{5} = ReadDisk(db,"$CalDB/DEMM") # [Enduse,Tech,EC,Area,Year] Maximum Device Efficiency Multiplier (Btu/Btu)
  DEStd::VariableArray{5} = ReadDisk(db,"$Input/DEStd") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standard (Btu/Btu)
  DEStdP::VariableArray{5} = ReadDisk(db,"$Input/DEStdP") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards Policy (Btu/Btu)
  #
  Change::VariableArray = zeros(Float32,length(Year)) # Change in Policy Variable
end

function ResPolicy(db)
  data = RControl(; db)
  (; CalDB,Input) = data
  (; Area,Areas,ECs,Enduses) = data
  (; Nation,Techs,Years) = data
  (; ANMap,DCCLimit,DEERef,DEE,DEM,DEMM,DEStd,DEStdP,Change) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[Areas,CN] .== 1)

  #
  # Default Value (for all Techs)
  #
  years = collect(Yr(2025):Final)
  for year in years
    Change[year]=0.023
  end

  for year in years, area in areas, ec in ECs, tech in Techs, enduse in Enduses
   if DEMM[enduse,tech,ec,area,year] > 0.0

     DEMM[enduse,tech,ec,area,year] = max(DEERef[enduse,tech,ec,area,year]*
        (1+Change[year])/(DEM[enduse,tech,ec,area]*0.98),
        DEMM[enduse,tech,ec,area,year]*(1+Change[year]))
        
      DEStdP[enduse,tech,ec,area,year] = min(DEM[enduse,tech,ec,area]*
        DEMM[enduse,tech,ec,area,year]*.98,max(DEStd[enduse,tech,ec,area,year],
        DEStdP[enduse,tech,ec,area,year]*(1+Change[year]),
        DEERef[enduse,tech,ec,area,year]*(1+Change[year])))
      
      DCCLimit[enduse,tech,ec,area,year]=3.0
    end
  end

  WriteDisk(db,"$Input/DCCLimit",DCCLimit)
  WriteDisk(db,"$CalDB/DEMM",DEMM)
  WriteDisk(db,"$Input/DEStdP",DEStdP)
end

function PolicyControl(db)
  @info "PCF_DeviceStd_Res.jl - PolicyControl"
  ResPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
