#
# OG_UnitDefinitions_VB.jl - Reads in characteristics of oil/gas plays for CN, US, and MX
#
using EnergyModel

module OG_UnitDefinitions_VB

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

  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelOG::SetArray = ReadDisk(db,"MainDB/FuelOGKey")
  FuelOGDS::SetArray = ReadDisk(db,"MainDB/FuelOGDS")
  FuelOGs::Vector{Int} = collect(Select(FuelOG))
  Fuels::Vector{Int} = collect(Select(Fuel))
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGUnitKey")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  #OGArea::Vector{String} = ReadDisk(db,"SpInput/OGArea") # [OGUnit] Area
  # OGCode::Vector{String} = ReadDisk(db,"MainDB/OGCode") # [OGUnit] OG Unit Code
  OGCounter::VariableArray{1} = ReadDisk(db,"SpInput/OGCounter") # [Year] Number of OG Units for this Year (Number)
  #OGECC::Vector{String} = ReadDisk(db,"SpInput/OGECC") # [OGUnit] Economic Sector
  #OGFuel::Vector{String} = ReadDisk(db,"SpInput/OGFuel") # [OGUnit] Fuel Type
  # OGName::Vector{String} = ReadDisk(db,"MainDB/OGName") # [OGUnit] OG Unit Name
  #OGNation::Vector{String} = ReadDisk(db,"SpInput/OGNation") # [OGUnit] Nation
  #OGNode::Vector{String} = ReadDisk(db,"SpInput/OGNode") # [OGUnit] Natural Gas Transmission Node
  #OGOGSw::Vector{String} = ReadDisk(db,"SpInput/OGOGSw") # [OGUnit] Oil or Gas Switch
  #OGProcess::Vector{String} = ReadDisk(db,"SpInput/OGProcess") # [OGUnit] Production Process
  #vOGArea::Vector{String} = ReadDisk(db,"VBInput/vOGArea") # [OGUnit] Area
  #vOGCode::Vector{String} = ReadDisk(db,"VBInput/vOGCode") # [OGUnit] OG Unit Code (Code)
  vOGCounter::VariableArray{1} = ReadDisk(db,"VBInput/vOGCounter") # [Year] Number of OG Units for this Year (Number)
  #vOGECC::Vector{String} = ReadDisk(db,"VBInput/vOGECC") # [OGUnit] Economic Sector (Name)
  #vOGFuel::Vector{String} = ReadDisk(db,"VBInput/vOGFuel") # [OGUnit] Fuel Type (Name)
  #vOGName::Vector{String} = ReadDisk(db,"VBInput/vOGName") # [OGUnit] OG Unit Name (Name)
  #vOGNation::Vector{String} = ReadDisk(db,"VBInput/vOGNation") # [OGUnit] Nation (Name)
  #vOGNode::Vector{String} = ReadDisk(db,"VBInput/vOGNode") # [OGUnit] Natural Gas Transmission Node (Name)
  #vOGOGSw::Vector{String} = ReadDisk(db,"VBInput/vOGOGSw") # [OGUnit] Oil or Gas Switch (Switch)
  #vOGProcess::Vector{String} = ReadDisk(db,"VBInput/vOGProcess") # [OGUnit] Production Process (Name)
  ByFrac::VariableArray{2} = ReadDisk(db,"SpInput/ByFrac") # [OGUnit,Year] Byproducts Production Fraction 
  vByFrac::VariableArray{2} = ReadDisk(db,"VBInput/vByFrac") # [OGUnit,Year] Byproducts Production Fraction (Btu/Btu)
  DilFrac::VariableArray{2} = ReadDisk(db,"SpInput/DilFrac") # [OGUnit,Year] Diluent Fraction (Btu/Btu)
  vDilFrac::VariableArray{2} = ReadDisk(db,"VBInput/vDilFrac") # [OGUnit,Year] Diluent Fraction (Btu/Btu)
  FkFrac::VariableArray{2} = ReadDisk(db,"SpInput/FkFrac") # [OGUnit,Year] Feedstock Fraction (Btu/Btu)
  vFkFrac::VariableArray{2} = ReadDisk(db,"VBInput/vFkFrac") # [OGUnit,Year] Feedstock Fraction (Btu/Btu)
  MeanEUR::VariableArray{2} = ReadDisk(db,"SpInput/MeanEUR") # [OGUnit,Year] Mean Expected Ultimate Recovery (TBtu/Well)
  vMeanEUR::VariableArray{2} = ReadDisk(db,"VBInput/vMeanEUR") # [OGUnit,Year] Mean Expected Ultimate Recovery (TBtu/Well)
  OGFMap::VariableArray{2} = ReadDisk(db,"SpInput/OGFMap") # [FuelOG,Fuel] Map between FuelOG and Fuel
  vOGFMap::VariableArray{2} = ReadDisk(db,"VBInput/vOGFMap") # [FuelOG,Fuel] Map between FuelOG and Fuel (Map)

end

function SCalibration(db)
  data = SControl(; db)
  (;Fuel,FuelDS,FuelOG,FuelOGDS,FuelOGs,Fuels,OGUnit,OGUnits,Year,YearDS) = data
  (;Years) = data
  (;ByFrac,vByFrac,DilFrac,vDilFrac,FkFrac,vFkFrac,MeanEUR,vMeanEUR,OGFMap,vOGFMap) = data
  (;OGCounter,vOGCounter) = data  
  #(;OGArea,OGCounter,OGECC,OGFuel,OGNation,OGNode,OGOGSw,OGProcess) = data
  #(;vOGArea,vOGCode,vOGCounter,vOGECC,vOGFuel,vOGName,vOGNation,vOGNode,vOGOGSw,vOGProcess) = data

  # OGName = vOGName
  #@. OGNation = vOGNation
  #@. OGNode = vOGNode
  #@. OGArea = vOGArea
  #@. OGFuel = vOGFuel
  #@. OGOGSw = vOGOGSw
  #@. OGECC = vOGECC
  #@. OGProcess = vOGProcess

  #WriteDisk(db,"SpInput/OGNation",OGNation)
  #WriteDisk(db,"SpInput/OGNode",OGNode)
  #WriteDisk(db,"SpInput/OGArea",OGArea)
  #WriteDisk(db,"SpInput/OGFuel",OGFuel)
  #WriteDisk(db,"SpInput/OGOGSw",OGOGSw)
  #WriteDisk(db,"SpInput/OGECC",OGECC)
  #WriteDisk(db,"SpInput/OGProcess",OGProcess)
  
  @. OGCounter = vOGCounter  
  WriteDisk(db,"SpInput/OGCounter",OGCounter)

  @. ByFrac = vByFrac
  WriteDisk(db,"SpInput/ByFrac",ByFrac)

  @. DilFrac = vDilFrac
  WriteDisk(db,"SpInput/DilFrac",DilFrac)

  @. FkFrac = vFkFrac
  WriteDisk(db,"SpInput/FkFrac",FkFrac)

  @. MeanEUR = vMeanEUR
  WriteDisk(db,"SpInput/MeanEUR",MeanEUR)

  @. OGFMap = vOGFMap
  WriteDisk(db,"SpInput/OGFMap",OGFMap)

end

function CalibrationControl(db)
  @info "OG_UnitDefinitions_VB.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
