#
# Electric_ImportEmissions_CA.jl
#

using EnergyModel

module Electric_ImportEmissions_CA

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXDS::SetArray = ReadDisk(db,"MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  POCXOthImports::VariableArray{4} = ReadDisk(db,"EGInput/POCXOthImports") # [Poll,NodeX,Area,Year] Imported Emissions Coefficients (Tonnes/GWh)

  # Scratch Variables
  Multiplier::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Import Emission Multiplier (Tonnes/GWh/(Tonnes/GWh))
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Area,Areas,Polls,NodeXs) = data 
  (; POCXOthImports) = data
  
  # *
  # * Dampen import emissions in future to match CEC 2022 Scoping Plan Forecast.
  # * Per Jeff. 09/26/23 R.Levesque
  # *
  
  CA = Select(Area,"CA")
  for poll in Polls, nodex in NodeXs
    POCXOthImports[poll,nodex,CA,Yr(2030)] = POCXOthImports[poll,nodex,CA,Yr(2030)]*0.20
    POCXOthImports[poll,nodex,CA,Yr(2050)] = POCXOthImports[poll,nodex,CA,Yr(2045)]*0.20
  end
  
  # *
  # * Interpolate from 2021
  # *
  
  years = collect(Yr(2024):Yr(2029))
  for year in years, poll in Polls, nodex in NodeXs
    POCXOthImports[poll,nodex,CA,year] = POCXOthImports[poll,nodex,CA,year-1] + 
    (POCXOthImports[poll,nodex,CA,Yr(2030)]-POCXOthImports[poll,nodex,CA,Yr(2021)])/(2030-2021)
  end

  years = collect(Yr(2031):Yr(2044))
  for year in years, poll in Polls, nodex in NodeXs
    POCXOthImports[poll,nodex,CA,year] = POCXOthImports[poll,nodex,CA,year-1] + 
    (POCXOthImports[poll,nodex,CA,Yr(2045)]-POCXOthImports[poll,nodex,CA,Yr(2030)])/(2045-2030)
  end
  
  WriteDisk(db,"EGInput/POCXOthImports",POCXOthImports)
end

function PolicyControl(db)
  @info "Electric_ImportEmissions_CA.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
