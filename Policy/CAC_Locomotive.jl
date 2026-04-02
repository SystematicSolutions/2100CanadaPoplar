#
# CAC_Locomotive.jl 
# This txp simulates the impact of the following Transport Canada policy 
# to control criteria air contaminant emissions from locomotives:
# Locomotive Emissions Regulations, under the Railway Safety Act 
#
# Details available in this file: 
#  \\ncr.int.ec.gc.ca\shares\e\ECOMOD\CACs\Policy Files\2019\Locomotive Emission Regulations\CAC_locomotive Reg 2019.08.15.xlsx
#
# Last edited by Audrey Bernard 20/09/03
#

using EnergyModel

module CAC_Locomotive

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Last,Future,DB,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TControl
  db::String

  Input::String = "TInput"
  
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  POCX::VariableArray{7} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)

  #
  # Scratch Variables
  #
  Reduce::VariableArray{2} = zeros(Float32,length(Poll),length(Year)) # [Poll,Year] Scratch Variable For Input Reductions
end

function TransPolicy(db)
  data = TControl(; db)
  (; Input) = data
  (; Areas,EC,FuelEP,Enduses,Poll,Tech,Years,Year) = data
  (; POCX,Reduce) = data
  
  @. Reduce = 1.0

  tech = Select(Tech,"TrainDiesel")
  years = collect(Yr(2023):Yr(2050))
  
  poll = Select(Poll,"NOX")
  Reduce[poll,years] = [
  #  2023   2024   2025   2026   2027   2028   2029   2030   2031   2032   2033   2034   2035   2036   2037   2038   2039   2040   2041   2042   2043   2044   2045   2046   2047   2048   2049   2050
  0.9335 0.9202 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070 0.9070]
  
  poll = Select(Poll,"PM10")
  Reduce[poll,years] = [
  #  2023   2024   2025   2026   2027   2028   2029   2030   2031   2032   2033   2034   2035   2036   2037   2038   2039   2040   2041   2042   2043   2044   2045   2046   2047   2048    2049   2050
  0.9430 0.9316 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200 0.9200  0.9200 0.9200]

  #HC 1.0 0.9582 0.9164 0.8746 0.8328 0.7910 0.7492 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072
  
  poll = Select(Poll,"COX")
  Reduce[poll,years] = [
  #  2023   2024   2025   2026   2027   2028   2029   2030   2031   2032   2033   2034   2035   2036   2037   2038   2039   2040   2041   2042   2043   2044   2045   2046   2047   2048   2049   2050 
  0.8845 0.8614 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380 0.8380]

  poll = Select(Poll,"VOC")
  Reduce[poll,years] = [
  #  2023   2024   2025   2026   2027   2028   2029   2030   2031   2032   2033   2034   2035   2036   2037   2038   2039   2040   2041   2042   2043   2044   2045   2046   2047   2048   2049   2050
  0.7910 0.7492 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072 0.7072]

  ecs = Select(EC,["Passenger","Freight"])
  polls = Select(Poll,["NOX","PM10","COX","VOC"])
  fuel  = Select(FuelEP,"Diesel")
  years = collect(Future:Final) 
  
  for year in years, area in Areas, poll in polls, ec in ecs, eu in Enduses
    POCX[eu,fuel,tech,ec,poll,area,year] = min(POCX[eu,fuel,tech,ec,poll,area,Last]*
      Reduce[poll,year]/Reduce[poll,Last],POCX[eu,fuel,tech,ec,poll,area,year])
  end

  WriteDisk(db,"$Input/POCX",POCX) 

end

function PolicyControl(db)
  @info "CAC_Locomotive.jl - PolicyControl"
  TransPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
