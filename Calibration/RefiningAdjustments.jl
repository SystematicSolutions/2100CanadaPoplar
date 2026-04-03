#
# RefiningAdjustments.jl - Historical Oil Refining Production
#
using EnergyModel

module RefiningAdjustments

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  TotDemand::VariableArray{4} = ReadDisk(db,"SOutput/TotDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)
  xRPPAdjustArea::VariableArray{3} = ReadDisk(db,"SpInput/xRPPAdjustArea") # [Fuel,Area,Year] Refined Petroleum Products (RPP) Supply Adjustments (TBtu/Yr)
  xRPPDemandArea::VariableArray{3} = ReadDisk(db,"SpInput/xRPPDemandArea") # [Fuel,Area,Year] Refined Petroleum Products (RPP) Demands (TBtu/Yr)
  xRPPExportsArea::VariableArray{3} = ReadDisk(db,"SpInput/xRPPExportsArea") # [Fuel,Area,Year] Refined Petroleum Products (RPP) Exports (TBtu/Yr)
  xRPPExportsROW::VariableArray{3} = ReadDisk(db,"SpInput/xRPPExportsROW") # [Fuel,Area,Year] RPP Exports to ROW (TBtu/Yr)
  xRPPImportsArea::VariableArray{3} = ReadDisk(db,"SpInput/xRPPImportsArea") # [Fuel,Area,Year] Refined Petroleum Products (RPP) Imports (TBtu/Yr)
  xRPPImportsROW::VariableArray{3} = ReadDisk(db,"SpInput/xRPPImportsROW") # [Fuel,Area,Year] RPP Imports from (TBtu/Yr)
  xRPPProdArea::VariableArray{3} = ReadDisk(db,"SpInput/xRPPProdArea") # [Fuel,Area,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)
end

function SCalibration(db)
  data = SControl(; db)
  (;Areas,ECCs,Fuel,Years) = data
  (;TotDemand,xRPPAdjustArea,xRPPDemandArea,xRPPExportsArea) = data
  (;xRPPExportsROW,xRPPImportsArea,xRPPImportsROW,xRPPProdArea) = data

  fuels = Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline","HFO","JetFuel",
              "Kerosene","LFO","LPG","Lubricants","Naphtha","NonEnergy",
              "PetroFeed","PetroCoke","StillGas"])

  for fuel in fuels, area in Areas, year in Years
    #
    # RPP Demands
    #
    xRPPDemandArea[fuel,area,year] = sum(TotDemand[fuel,ecc,area,year] for ecc in ECCs)

    #
    # Refining Adjustments
    #
    xRPPAdjustArea[fuel,area,year] = 
      xRPPDemandArea[fuel,area,year]-xRPPProdArea[fuel,area,year]+xRPPExportsArea[fuel,area,year]-
      xRPPImportsArea[fuel,area,year]+xRPPExportsROW[fuel,area,year]-xRPPImportsROW[fuel,area,year]
  end

  for fuel in fuels, area in Areas, year in Yr(2013):Final
    xRPPAdjustArea[fuel,area,year] = xRPPAdjustArea[fuel,area,year-1]
  end

  WriteDisk(db,"SpInput/xRPPDemandArea",xRPPDemandArea)
  WriteDisk(db,"SpInput/xRPPAdjustArea",xRPPAdjustArea)

end

function CalibrationControl(db)
  @info "RefiningAdjustments.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
