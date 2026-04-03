#
# SuPollution.jl
#

module SuPollution

import ...EnergyModel: ReadDisk,WriteDisk,Select,MaxTime,HisTime
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))

  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))

  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))

  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))

  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  CgFPol::VariableArray{4} = ReadDisk(db,"SOutput/CgFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Cogeneration Related Pollution (Tonnes/Yr)
  EnFPol::VariableArray{4} = ReadDisk(db,"SOutput/EnFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Enduse Energy Pollution (Tonnes/Yr)
  EnPol::VariableArray{3} = ReadDisk(db,"SOutput/EnPol",year) #[ECC,Poll,Area,Year]  Enduse Energy Related Pollution (Tonnes/Yr)
  EuFPol::VariableArray{4} = ReadDisk(db,"SOutput/EuFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Energy Pollution (Tonnes/Yr)
  FlPol::VariableArray{3} = ReadDisk(db,"SOutput/FlPol",year) #[ECC,Poll,Area,Year]  Fugitive Flaring Emissions (Tonnes/Yr)
  FuPol::VariableArray{3} = ReadDisk(db,"SOutput/FuPol",year) #[ECC,Poll,Area,Year]  Other Fugitive Emissions (Tonnes/Yr)
  MEPol::VariableArray{3} = ReadDisk(db,"SOutput/MEPol",year) #[ECC,Poll,Area,Year]  Non-Energy Pollution (Tonnes/Yr)
  NcPol::VariableArray{3} = ReadDisk(db,"SOutput/NcPol",year) #[ECC,Poll,Area,Year]  Non Combustion Related Pollution (Tonnes/Yr)
  ORMEPol::VariableArray{3} = ReadDisk(db,"SOutput/ORMEPol",year) #[ECC,Poll,Area,Year]  Non-Energy Off Road Pollution (Tonnes/year)
  SqPol::VariableArray{3} = ReadDisk(db,"SOutput/SqPol",year) #[ECC,Poll,Area,Year]  Sequestering Emissions (Tonnes/Yr)
  StFPol::VariableArray{3} = ReadDisk(db,"SOutput/StFPol",year) #[FuelEP,Poll,Area,Year]  Steam Generation Pollution (Tonnes/Yr)
  TotPol::VariableArray{3} = ReadDisk(db,"SOutput/TotPol",year) #[ECC,Poll,Area,Year]  Pollution (Tonnes/Yr)
  VnPol::VariableArray{3} = ReadDisk(db,"SOutput/VnPol",year) #[ECC,Poll,Area,Year]  Fugitive Venting Emissions (Tonnes/Yr)
end

function PollutionTotals(data::Data)
  (; db,year) = data
  (; Areas,ECC,ECCs,FuelEPs,Polls) = data #sets
  (; CgFPol,EnFPol,EnPol,EuFPol,FlPol,FuPol,MEPol,NcPol) = data
  (; ORMEPol,SqPol,StFPol,TotPol,VnPol) = data

  # @debug "  SuPollution.jl - PollutionTotals"

  #
  # Steam Generation Pollution
  #
  for area in Areas, poll in Polls, steam in Select(ECC,"Steam"), fuelep in FuelEPs
    EuFPol[fuelep,steam,poll,area] = StFPol[fuelep,poll,area]
  end
  WriteDisk(db,"SOutput/EuFPol",year,EuFPol)

  #
  # Energy Emissions including Cogeneration
  #
  for area in Areas, poll in Polls, ecc in ECCs, fuelep in FuelEPs
    EnFPol[fuelep,ecc,poll,area] = EuFPol[fuelep,ecc,poll,area]+CgFPol[fuelep,ecc,poll,area]
  end

  #
  # Total Energy Emissions
  #
  for area in Areas, poll in Polls, ecc in ECCs
    EnPol[ecc,poll,area] = sum(EnFPol[fuelep,ecc,poll,area] for fuelep in FuelEPs)
  end
  WriteDisk(db,"SOutput/EnPol",year,EnPol)
  WriteDisk(db,"SOutput/EnFPol",year,EnFPol)

  #
  # Total Pollution
  #
  for area in Areas, poll in Polls, ecc in ECCs
    TotPol[ecc,poll,area] = EnPol[ecc,poll,area]+NcPol[ecc,poll,area]+
      MEPol[ecc,poll,area]+VnPol[ecc,poll,area]+FlPol[ecc,poll,area]+
      FuPol[ecc,poll,area]+ORMEPol[ecc,poll,area]+SqPol[ecc,poll,area]
  end
  WriteDisk(db,"SOutput/TotPol",year,TotPol)

end # function PollutionTotals

end # module SuPollution
