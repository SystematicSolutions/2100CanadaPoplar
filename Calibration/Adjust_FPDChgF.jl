#
#Adjust_FPDChgF.jl
#
using EnergyModel

module Adjust_FPDChgF

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Adjust_FPDChgFCalib
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  FPDChgF::VariableArray{4} = ReadDisk(db,"SCalDB/FPDChgF") # [Fuel,ES,Area,Year] Fuel Delivery Charge ($/mmBtu)
  FPF::VariableArray{4} = ReadDisk(db,"SOutput/FPF") # [Fuel,ES,Area,Year] Delivered Fuel Price ($/mmBtu)
  FPMarginF::VariableArray{4} = ReadDisk(db,"SInput/FPMarginF") # [Fuel,ES,Area,Year] Refinery/Distributor Margin ($/$)
  FPSMF::VariableArray{4} = ReadDisk(db,"SInput/FPSMF") # [Fuel,ES,Area,Year] Energy Sales Tax ($/$)
  FPTaxF::VariableArray{4} = ReadDisk(db,"SInput/FPTaxF") # [Fuel,ES,Area,Year] Fuel Tax (Real $/mmBtu)
  xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Exogenous Price Normal (Real $/mmBtu)
  xFPF::VariableArray{4} = ReadDisk(db,"SInput/xFPF") # [Fuel,ES,Area,Year] Delivered Fuel Prices (Real $/mmBtu)

end

function Adjust_FPDChgFCalibration(db)
  data = Adjust_FPDChgFCalib(; db)
  (;Area,Areas,ES,ESs,Fuel,Fuels,Nation) = data
  (;FPDChgF,FPF,FPMarginF,FPSMF,FPTaxF,xENPN,xFPF) = data

  AreasCanada = Select(Area, (from = "ON", to = "NU"))
  years = collect(Yr(2019):Yr(2023))

  for fuel in Fuels,es in ESs,area in Areas
    FPDChgF[fuel,es,area,Yr(2024)] = sum(FPDChgF[fuel,es,area,year]/5.0 for year in years)
  end

  years = collect(Yr(2025):Yr(2050))

  for fuel in Fuels,es in ESs,area in Areas, year in years
    FPDChgF[fuel,es,area,year] = FPDChgF[fuel,es,area,Yr(2024)]
  end
  #
  # Re-align fuels that are set to match other delivered prices
  #
  years = collect(Yr(2018):Final)
  Canada = Select(Nation, "CN")
  Coal = Select(Fuel, "Coal")
  PetroCoke = Select(Fuel, "PetroCoke")
  # PetroCoke matches Coal
  for es in ESs,area in AreasCanada,year in years
    FPDChgF[PetroCoke,es,area,year] = xFPF[Coal,es,area,year]/
        (1+FPSMF[PetroCoke,es,area,year])-xENPN[PetroCoke,Canada,year]*
        (1+FPMarginF[PetroCoke,es,area,year])-FPTaxF[PetroCoke,es,area,year]
  end

  LFO = Select(Fuel, "LFO")
  LPG = Select(Fuel, "LPG")
  # LPG matches LFO for some sectors
  sectors = Select(ES,["Residential","Commercial"])
  for es in sectors,area in AreasCanada, year in years
    FPDChgF[LPG,es,area,year] = FPDChgF[LPG,es,area,year]-
                               (FPF[LPG,es,area,year]-FPF[LFO,es,area,year])
  end

  Comm = Select(ES, "Commercial")
  Trans = Select(ES, "Transport")

  for area in AreasCanada,year in years
    FPDChgF[LPG,Trans,area,year] = FPDChgF[LPG,Trans,area,year]-
                                 (FPF[LPG,Trans,area,year]-FPF[LFO,Comm,area,year])
  end

  WriteDisk(db,"SCalDB/FPDChgF",FPDChgF)
end

function Control(db)
  @info "Adjust_FPDChgF.jl - Control"
  Adjust_FPDChgFCalibration(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
