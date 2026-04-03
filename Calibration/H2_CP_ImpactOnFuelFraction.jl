#
# H2_CP_ImpactOnFuelFraction.jl
#
using EnergyModel

module H2_CP_ImpactOnFuelFraction

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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  FPCPFrac::VariableArray{4} = ReadDisk(db,"$Input/FPCPFrac") # [Fuel,EC,Area,Year] Portion of Carbon Price which impacts Fungible Fuel Fraction ($/$)

  # Scratch Variables
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Fuel,Fuels,Years,ECs,Areas) = data
  (;FPCPFrac) = data
   
  fuels = Select(Fuel,["Hydrogen","NaturalGas"])
  for year in Years, area in Areas, ec in ECs, fuel in fuels 
    FPCPFrac[fuel,ec,area,year] = 0.0
  end

  WriteDisk(db,"$Input/FPCPFrac",FPCPFrac)

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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  FPCPFrac::VariableArray{4} = ReadDisk(db,"$Input/FPCPFrac") # [Fuel,EC,Area,Year] Portion of Carbon Price which impacts Fungible Fuel Fraction ($/$)

  # Scratch Variables
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Fuel,Years,ECs,Fuels,Areas) = data
  (;FPCPFrac) = data
   
  fuels = Select(Fuel,["Hydrogen","NaturalGas"])
  for year in Years, area in Areas, ec in ECs, fuel in fuels 
    FPCPFrac[fuel,ec,area,year] = 0.0
  end

  WriteDisk(db,"$Input/FPCPFrac",FPCPFrac)

end

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  FPCPFrac::VariableArray{4} = ReadDisk(db,"$Input/FPCPFrac") # [Fuel,EC,Area,Year] Portion of Carbon Price which impacts Fungible Fuel Fraction ($/$)

  # Scratch Variables
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Fuel,Fuels,ECs,Years,Areas) = data
  (;FPCPFrac) = data
   
  fuels = Select(Fuel,["Hydrogen","NaturalGas","Diesel"])
  for year in Years, area in Areas, ec in ECs, fuel in fuels 
    FPCPFrac[fuel,ec,area,year] = 0.0
  end

  WriteDisk(db,"$Input/FPCPFrac",FPCPFrac)

end

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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  FPCPFrac::VariableArray{4} = ReadDisk(db,"$Input/FPCPFrac") # [Fuel,EC,Area,Year] Portion of Carbon Price which impacts Fungible Fuel Fraction ($/$)

  # Scratch Variables
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Fuel,Fuels,Years,ECs,Areas) = data
  (;FPCPFrac) = data
   
  fuels = Select(Fuel,["Biodiesel","Ethanol"])
  for year in Years, area in Areas, ec in ECs, fuel in fuels 
    FPCPFrac[fuel,ec,area,year] = 0.0
  end

  WriteDisk(db,"$Input/FPCPFrac",FPCPFrac)

end

function CalibrationControl(db)
  @info "H2_CP_ImpactOnFuelFraction.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
