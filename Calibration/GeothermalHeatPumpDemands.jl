#
# GeothermalHeatPumpDemands.jl - Electricity demand (xDmd) for geothermal 
#    and air source heat pump is included in Tech=Electricity for Res/Com.
#    This file assigns values for xDmd(Tech=Geothermal & Tech=HeatPump).
#
using EnergyModel

module GeothermalHeatPumpDemands

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1] # Year for capital costs [tv]  
  HPGeoFraction::VariableArray{3} = ReadDisk(db,"$Input/HPGeoFraction") # [EC,Area,Year] Air Source Heat Pump Fraction of Geothermal Demand (TBtu/TBtu)
  xDEEGeoHP::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)

  # Scratch Variables
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Area,ECs,Enduses) = data
  (;Tech,Years) = data
  (;CurTime,HPGeoFraction,xDEEGeoHP,xDmd) = data

  #*
  #* Apply adjustments only to Canada. 06-12-23 R.Levesque
  #*
  AreasCanada = Select(Area,(from = "ON", to = "NU"))
  
  #*
  #* Adjust electric to remove geothermal and heat pump electricity
  #* Assign air source heat pump as fraction of geothermal
  #* Divide by efficiency to calc. geothermal & heat pump electric usage
  #
  HeatPump = Select(Tech,"HeatPump")
  Geothermal = Select(Tech,"Geothermal")
  Electric = Select(Tech,"Electric")

  curtime = Int(CurTime)
  for enduse in Enduses, ec in ECs, area in AreasCanada

  #* The input "xDmd(EU,Geothermal,EC,Area,Y)" contains both the Heat Pump
  #* demands and the Geothermal demands.  These demands are split between
  #* Heat Pump and Geothermal (HPGeoFraction), then we calculate the amount
  #* of electricity needed for the Heat Pump and Geothermal systems.
    for year in Years
      @finite_math xDmd[enduse,HeatPump,ec,area,year] = xDmd[enduse,Geothermal,ec,area,year]*
                                           HPGeoFraction[ec,area,year] / 
                                           xDEEGeoHP[enduse,HeatPump,ec,area,curtime]
      @finite_math xDmd[enduse,Geothermal,ec,area,year] = xDmd[enduse,Geothermal,ec,area,year]*
                                           (1-HPGeoFraction[ec,area,year]) / 
                                           xDEEGeoHP[enduse,Geothermal,ec,area,curtime]
  #*
  #* Remove GeoHP demands from Electric to avoid double counting
  #
      GeoHP = Select(Tech,["HeatPump","Geothermal"])
      xDmd[enduse,Electric,ec,area,year] = xDmd[enduse,Electric,ec,area,year] -
                                           sum(xDmd[enduse,tech,ec,area,year] for tech in GeoHP)
    end
  end

  WriteDisk(db,"$Input/xDmd",xDmd)

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1]  
  HPGeoFraction::VariableArray{3} = ReadDisk(db,"$Input/HPGeoFraction") # [EC,Area,Year] Air Source Heat Pump Fraction of Geothermal Demand (TBtu/TBtu)
  xDEEGeoHP::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)

  # Scratch Variables
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Area,ECs,Enduses) = data
  (;Tech,Years) = data
  (;CurTime,HPGeoFraction,xDEEGeoHP,xDmd) = data

  #*
  #* Apply adjustments only to Canada. 06-12-23 R.Levesque
  #*
  AreasCanada = Select(Area,(from = "ON", to = "NU"))
  
  #*
  #* Adjust electric to remove geothermal and heat pump electricity
  #* Assign air source heat pump as fraction of geothermal
  #* Divide by efficiency to calc. geothermal & heat pump electric usage
  #
  HeatPump = Select(Tech,"HeatPump")
  Geothermal = Select(Tech,"Geothermal")
  Electric = Select(Tech,"Electric")

  curtime = Int(CurTime)
  for enduse in Enduses, ec in ECs, area in AreasCanada
    
  #* The input "xDmd(EU,Geothermal,EC,Area,Y)" contains both the Heat Pump
  #* demands and the Geothermal demands.  These demands are split between
  #* Heat Pump and Geothermal (HPGeoFraction), then we calculate the amount
  #* of electricity needed for the Heat Pump and Geothermal systems.
    for year in Years
      @finite_math xDmd[enduse,HeatPump,ec,area,year] = xDmd[enduse,Geothermal,ec,area,year]*
                                           HPGeoFraction[ec,area,year] / 
                                           xDEEGeoHP[enduse,HeatPump,ec,area,curtime]
      @finite_math xDmd[enduse,Geothermal,ec,area,year] = xDmd[enduse,Geothermal,ec,area,year]*
                                           (1-HPGeoFraction[ec,area,year]) / 
                                           xDEEGeoHP[enduse,Geothermal,ec,area,curtime]
  #*
  #* Remove GeoHP demands from Electric to avoid double counting
  #
      GeoHP = Select(Tech,["HeatPump","Geothermal"])
      xDmd[enduse,Electric,ec,area,year] = xDmd[enduse,Electric,ec,area,year] -
                                           sum(xDmd[enduse,tech,ec,area,year] for tech in GeoHP)
    end
  end

  WriteDisk(db,"$Input/xDmd",xDmd)

end

function CalibrationControl(db)
  @info "GeothermalHeatPumpDemands.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
