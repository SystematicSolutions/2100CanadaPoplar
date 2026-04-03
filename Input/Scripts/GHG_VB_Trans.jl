#
# GHG_VB_Trans.jl - Moves VBInput data into transportation databases
#
using EnergyModel

module GHG_VB_Trans

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

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
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  FuelFs::SetArray = ReadDisk(db,"MainDB/FuelFsKey")
  FuelFsDS::SetArray = ReadDisk(db,"MainDB/FuelFsDS")
  FuelFss::Vector{Int} = collect(Select(FuelFs))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  FFsMap::VariableArray{2} = ReadDisk(db,"SInput/FFsMap") # [FuelFs,Fuel] Map between FuelFs and Fuel
  FsPOCX::VariableArray{6} = ReadDisk(db,"$Input/FsPOCX") # [Fuel,Tech,EC,Poll,Area,Year] Feedstock Pollution Coefficient (Tonnes/TBtu)
  POCX::VariableArray{7} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Enduse Energy Pollution Coefficients (Tonnes/TBtu)
  vTrPOCX::VariableArray{6} = ReadDisk(db,"VBInput/vTrPOCX") # [FuelEP,Tech,EC,Poll,vArea,Year] Transportation Pollution Coefficient (Tonnes/TBtu)
  vTrFsPOCX::VariableArray{6} = ReadDisk(db,"VBInput/vTrFsPOCX") # [FuelFs,Tech,EC,Poll,vArea,Year] Transportation Feedstock Pollution Coefficient (Tonnes/TBtu)
  vTrMEPol::VariableArray{5} = ReadDisk(db,"VBInput/vTrMEPol") # [Tech,EC,Poll,vArea,Year] Non-Energy Pollution (Tonnes/Yr)
  xTrMEPol::VariableArray{5} = ReadDisk(db,"$Input/xTrMEPol") # [Tech,EC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr)

end

function Emissions(db)
  data = TControl(; db)
  (;Input) = data
  (;Area,ECs,Enduses,Fuel,Fuels,FuelEPs,FuelFs,FuelFss) = data
  (;Nation,Poll,Polls,Techs,vArea,Years) = data
  (;ANMap,FFsMap,FsPOCX,POCX,vTrPOCX,vTrFsPOCX,vTrMEPol,xTrMEPol) = data
  
  CN = Select(Nation,"CN");
  areas = findall(ANMap[:,CN] .== 1)
  polls = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  
  #
  # @info "Reading Transportation GHG POCX" 
  #
  
  # 
  # Set previous values for POCX to zero
  # 
  for eu in Enduses, fuel in FuelEPs, tech in Techs, ec in ECs, poll in polls, area in areas, year in Years
    POCX[eu,fuel,tech,ec,poll,area,year] = 0
  end
  for eu in Enduses, fuel in Fuels, tech in Techs, ec in ECs, poll in polls, area in areas, year in Years
    FsPOCX[fuel,tech,ec,poll,area,year] = 0
  end


   #
   # @info "Transfer Transportation TrPOCX from VBInput"
   #
   for eu in Enduses,fuel in FuelEPs,tech in Techs,ec in ECs,poll in polls, area in areas, year in Years
     varea = Select(vArea,Area[area])
     POCX[eu,fuel,tech,ec,poll,area,year] = vTrPOCX[fuel,tech,ec,poll,varea,year]
   end
  
  years = collect(Future:Final)
  for eu in Enduses,fuel in FuelEPs,tech in Techs,ec in ECs,poll in polls, area in areas, year in years
    if POCX[eu,fuel,tech,ec,poll,area,year] == 0.0
      POCX[eu,fuel,tech,ec,poll,area,year]=POCX[eu,fuel,tech,ec,poll,area,year-1]
    end
  end
  WriteDisk(db,"$Input/POCX",POCX)
  
  #
  # @info "Reading Transportation GHG FsPOCX" 
  #
  for fuelfs in FuelFss,tech in Techs,ec in ECs,poll in Polls,area in areas, year in Years
    varea = Select(vArea,Area[area])
    fuel=Select(Fuel,FuelFs[fuelfs])
    FsPOCX[fuel,tech,ec,poll,area,year] = vTrFsPOCX[fuelfs,tech,ec,poll,varea,year]
  end
    
  years = collect(Future:Final)  
  for fuel in Fuels,tech in Techs,ec in ECs,poll in Polls,area in areas, year in years
    if FsPOCX[fuel,tech,ec,poll,area,year] == 0.0
      FsPOCX[fuel,tech,ec,poll,area,year] = FsPOCX[fuel,tech,ec,poll,area,year-1]
    end
  end
  WriteDisk(db,"$Input/FsPOCX",FsPOCX)
  
  #
  # @info "Transfer Transportation TrMEPol from VBInput"
  #
  for tech in Techs,ec in ECs,poll in polls, area in areas, year in Years
    varea = Select(vArea,Area[area])
    xTrMEPol[tech,ec,poll,area,year] = vTrMEPol[tech,ec,poll,varea,year]
  end
  WriteDisk(db,"$Input/xTrMEPol",xTrMEPol)
end

function Control(db)
  @info "GHG_VB_Trans.jl - Control"
  Emissions(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
