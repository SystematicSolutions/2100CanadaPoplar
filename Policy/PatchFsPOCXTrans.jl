#
# PatchFsPOCXTrans.jl - Patch for Transportation FsPOCX - Jeff Amloin 2/14/25
#
using EnergyModel

module PatchFsPOCXTrans

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
  FsPOCS::VariableArray{6} = ReadDisk(db,"$Input/FsPOCS") # [Fuel,Tech,EC,Poll,Area,Year] Feedstock Pollution Standards (Tonnes/TBtu)
  FsPOCX::VariableArray{6} = ReadDisk(db,"$Input/FsPOCX") # [Fuel,Tech,EC,Poll,Area,Year] Feedstock Pollution Coefficient (Tonnes/TBtu)

end

function Emissions(db)
  data = TControl(; db)
  (;Input) = data
  (;Area,ECs,Enduses,Fuel) = data
  (;Nation,Poll,Polls,Techs,Years) = data
  (;ANMap,FsPOCS,FsPOCX) = data
  
  #
  # @info "Patch for Transportation FsPOCX" 
  #  
  CN = Select(Nation,"CN");
  areas = findall(ANMap[:,CN] .== 1)
  poll = Select(Poll,"CO2")
  fuel = Select(Fuel,"Lubricants")
  for year in Years, area in areas, ec in ECs, tech in Techs
    FsPOCX[fuel,tech,ec,poll,area,year] = 60878
  end
  WriteDisk(db,"$Input/FsPOCX",FsPOCX)
  
  @. FsPOCS = 1e12   
  WriteDisk(db,"$Input/FsPOCS",FsPOCS)

end

function PolicyControl(db)
  @info "PatchFsPOCXTrans.jl - PolicyControl"
  Emissions(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
