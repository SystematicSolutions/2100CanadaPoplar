#
# Trans_BiofuelEmissions_CA.jl
#

using EnergyModel

module Trans_BiofuelEmissions_CA

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
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

  # Scratch Variables
 # Index2029     'Index for year 2029'
 # Index2030     'Index for year 2030'
end

function TransPolicy(db)
  data = TControl(; db)
  (; Input) = data
  (; Area,ECs) = data
  (; FuelEP,Polls) = data
  (; Techs) = data
  (; POCX) = data

  #
  # Historically Ethanol shared the Gasoline emission factor
  # In the forecast trend this factor to zero. - Jeff Amlin 9/23/23
  # 
  CA = Select(Area,"CA")
  # Carriage = Select(Enduse,"Carriage")
  Ethanol = Select(FuelEP,"Ethanol")

  years = collect(Yr(2030):Final)
  for year in years, poll in Polls, ec in ECs, tech in Techs
    POCX[1,Ethanol,tech,ec,poll,CA,year] = 0.0
  end
  years = collect(Future:Yr(2029))
  for year in years, poll in Polls, ec in ECs, tech in Techs
    POCX[1,Ethanol,tech,ec,poll,CA,year] = POCX[1,Ethanol,tech,ec,poll,CA,year-1]+
      (POCX[1,Ethanol,tech,ec,poll,CA,Yr(2030)]-POCX[1,Ethanol,tech,ec,poll,CA,Last])/
      (Yr(2030)-Last)
  end

  #
  # Historically Biodiesel shared the Diesel emission factor
  # In the forecast trend this factor to zero. - Jeff Amlin 9/23/23
  #  
  Biodiesel = Select(FuelEP,"Biodiesel")

  years = collect(Yr(2030):Final)
  for year in years, poll in Polls, ec in ECs, tech in Techs
    POCX[1,Biodiesel,tech,ec,poll,CA,year] = 0.0
  end

  years = collect(Future:Yr(2029))
  for year in years, poll in Polls, ec in ECs, tech in Techs
    POCX[1,Biodiesel,tech,ec,poll,CA,year] = POCX[1,Biodiesel,tech,ec,poll,CA,year-1]+
      (POCX[1,Biodiesel,tech,ec,poll,CA,Yr(2030)]-POCX[1,Biodiesel,tech,ec,poll,CA,Last])/
      (Yr(2030)-Last)
  end

  WriteDisk(db,"$Input/POCX",POCX)
end

function PolicyControl(db)
  @info "Trans_BiofuelEmissions_CA.jl - PolicyControl"
  TransPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
