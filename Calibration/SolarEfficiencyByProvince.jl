#
# SolarEfficienciesByProvince.jl
#
using EnergyModel

module SolarEfficiencyByProvince

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1] # Year for capital costs [tv]  

  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 

  # Scratch Variables
  Data::VariableArray{1} = zeros(Float32,length(Area)) # [Area] Data input placeholder
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Area,ECs,Enduse,Tech) = data
  (;CurTime,DEM,xDEE) = data
  (;Data) = data
  
  #=*
  * This file adjusts the default input efficiencies for solar technologies
  * to account for differences in solar energy potential in each
  * province and territory. Initial efficiencies are from US New England
  * data, so use Ontario as the baseline and adjust all others.
  *
  * Adjustments are from "Solar Water Heating Buyer's Guide" document
  * sent by Robin White on 06/14/16 - Ian 07/20/16
  *=#
  curtime = Int(CurTime[1])
  areas = Select(Area,["ON","QC","BC","AB","SK","MB","NB","NS","PE",
                       "NL","YT","NT","NU"])
  Data[areas] = [
  #=ON=#      1.000
  #=QC=#      0.978
  #=BC=#      0.956
  #=AB=#      1.067
  #=SK=#      1.089
  #=MB=#      1.022
  #=NB=#      0.956
  #=NS=#      0.911
  #=PE=#      0.867
  #=NL=#      0.667
  #=YT=#      0.689
  #=NT=#      0.578
  #=NU=#      0.578  
  ]

  solar = Select(Tech,"Solar")
  hw = Select(Enduse,"HW")
  for ec in ECs, area in areas 
    xDEE[hw,solar,ec,area,curtime] =  xDEE[hw,solar,ec,area,curtime] * Data[area]
  end

  #*
  #* Costs should be the same across provinces so also adjust efficiency curve
  #*
  for ec in ECs, area in areas 
    DEM[hw,solar,ec,area] =  DEM[hw,solar,ec,area] * Data[area]
  end

  WriteDisk(db,"$Input/xDEE",xDEE)
  WriteDisk(db,"$Input/DEM",DEM)

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
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  # CurTime::VariableArray{1} = ReadDisk(db,"$Input/CurTime") # [tv] Year for capital costs
  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1] # Year for capital costs [tv]  
  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 

  # Scratch Variables
  Data::VariableArray{1} = zeros(Float32,length(Area)) # [Area] Data input placeholder
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Area,ECs,Enduse,Tech) = data
  (;CurTime,DEM,xDEE) = data
  (;Data) = data
  
  curtime = Int(CurTime[1])
  areas = Select(Area,["ON","QC","BC","AB","SK","MB","NB","NS","PE",
                       "NL","YT","NT","NU"])
  Data[areas] = [
  #=ON=#      1.000
  #=QC=#      0.978
  #=BC=#      0.956
  #=AB=#      1.067
  #=SK=#      1.089
  #=MB=#      1.022
  #=NB=#      0.956
  #=NS=#      0.911
  #=PE=#      0.867
  #=NL=#      0.667
  #=YT=#      0.689
  #=NT=#      0.578
  #=NU=#      0.578  
  ]

  solar = Select(Tech,"Solar")
  hw = Select(Enduse,"HW")
  for ec in ECs, area in areas 
    xDEE[hw,solar,ec,area,curtime] =  xDEE[hw,solar,ec,area,curtime] * Data[area]
  end

  #*
  #* Costs should be the same across provinces so also adjust efficiency curve
  #*
  for ec in ECs, area in areas 
    DEM[hw,solar,ec,area] =  DEM[hw,solar,ec,area] * Data[area]
  end

  WriteDisk(db,"$Input/xDEE",xDEE)
  WriteDisk(db,"$Input/DEM",DEM)

end

function CalibrationControl(db)
  @info "SolarEfficiencyByProvince.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
