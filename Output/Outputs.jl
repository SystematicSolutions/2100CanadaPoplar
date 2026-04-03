#
# Outputs.jl
#

module Outputs

import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

rm_dir_contents(OutputFolder)
create_folder() = isdir(dirname(OutputFolder)) || mkpath(dirname(OutputFolder))

Base.@kwdef struct OutputsData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCodeRef::Array{String} = ReadDisk(RefNameDB,"EGInput/UnCode") # [Unit] Unit Code
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnNationRef::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation

  #
  # Scratch Variables for Unit selection between Reference and Policy
  #
  # CurrentUnit   'Pointer to the Unit being Processed (Number)'
  # PolicyUnit    'Pointer to Policy Unit (Number)'
  # ReferenceUnit 'Pointer to Reference Unit (Number)'

end

#
# Find matching Reference case Unit
#
function FindUnitsToOutput(CurrentUnit,nation)
  db = DB
  data = OutputsData(;db)
  (; Nation,Units) = data
  (; UnCode,UnCodeRef,UnNation,UnNationRef) = data

    PolicyUnit = 0
    for unit in Units
      if UnCode[unit] == UnCode[CurrentUnit] && UnNation[unit] == Nation[nation]
        PolicyUnit = CurrentUnit
      end
    end
 
    ReferenceUnit = 0
    for unit in Units
      if UnCodeRef[unit] == UnCode[CurrentUnit] && UnNationRef[unit] == Nation[nation]
        ReferenceUnit = unit
      end
    end

  return PolicyUnit,ReferenceUnit
  
end # function FindUnitsToOutput


function initialize_conversion_data(data)
  (; Poll, Conversion, UnitsDS) = data
  
  # Initialize conversion factors
  poll_conversions = Dict(
    "SOX" => 0.001, "NOX" => 0.001, "PMT" => 0.001, "VOC" => 0.001,
    "N2O" => 0.001, "COX" => 0.001, "CO2" => 0.001, "CH4" => 0.001,
    "SF6" => 0.001, "PFC" => 0.001, "HFC" => 0.001, "PM25" => 0.001,
    "PM10" => 0.001, "Hg" => 1000.0, "O3" => 0.001, "NH3" => 0.001,
    "H2O" => 0.001, "BC" => 0.001, "NF3" => 0.001
  )
  
  # Initialize units descriptions
  poll_units = Dict(
    "SOX" => "Tonnes/TBtu", "NOX" => "Tonnes/TBtu", "PMT" => "Tonnes/TBtu", 
    "VOC" => "Tonnes/TBtu", "N2O" => "Tonnes/TBtu", "COX" => "Tonnes/TBtu", 
    "CO2" => "Tonnes/TBtu", "CH4" => "Tonnes/TBtu", "SF6" => "Tonnes/TBtu", 
    "PFC" => "Tonnes/TBtu", "HFC" => "Tonnes/TBtu", "PM25" => "Tonnes/TBtu",
    "PM10" => "Tonnes/TBtu", "Hg" => "Grams/TBtu", "O3" => "Tonnes/TBtu", 
    "NH3" => "Tonnes/TBtu", "H2O" => "Tonnes/TBtu", "BC" => "Tonnes/TBtu", 
    "NF3" => "Tonnes/TBtu"
  )
  
  for poll_idx in eachindex(Poll)
    poll_key = Poll[poll_idx]
    if haskey(poll_conversions, poll_key)
      Conversion[poll_idx] = poll_conversions[poll_key]
    else
      Conversion[poll_idx] = 1.0
    end
    
    if haskey(poll_units, poll_key)
      UnitsDS[poll_idx] = poll_units[poll_key]
    else
      UnitsDS[poll_idx] = "Units"
    end
  end
end




#
# ElectricUnits
#
#include("../Output/AccessOutput/ElectricUnits/zUnPOCA.jl")
# include("../Output/AccessOutput/ElectricUnits/zUnPol.jl")
#include("../Output/AccessOutput/ElectricUnits/zUnRCGA.jl")

#
#
# /AccessOutput/TransPollution
#
#include("../Output/AccessOutput/TransPollution/zTrOREnFPol.jl")

#
# Excel Outputs
#
function Excel_Outputs(db)
  @info "Outputs.jl - Excel_Outputs"
end # Excel_Outputs

#
# Access Outputs
#
function Access_Outputs(db)
  @info "Outputs.jl - Access_Outputs"
  
  #
  # ElectricUnits
  # 
  #zUnPOCA_DtaControl(db)
  # zUnPol_DtaControl(db)
  #zUnRCGA_DtaControl(db)
  
  #
  # /AccessOutput/TransPollution
  #
  #zTrOREnFPol_DtaControl(db,SceName)
  
end # Access_Outputs

function Outputs_Control(db,SceName,OutputType)
  @info "Outputs.jl - Outputs_Control - Generate $OutputType Outputs for $SceName scenario"
  if OutputType == "ExcelDTAs"
    Excel_Outputs(db)
  elseif OutputType == "AccessDTAs"
    Access_Outputs(db)
  elseif OutputType == "All"
    Excel_Outputs(db)  
    Access_Outputs(db)  
  elseif OutputType == "Test"
    # Note: Files in the "Test" bin are temporary.
    # zUnPol_DtaControl(db)
  end
end

end
