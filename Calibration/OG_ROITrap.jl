#
# OG_ROITrap.jl
#
using EnergyModel

module OG_ROITrap

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name
  OGRefNameDB::String = ReadDisk(db,"MainDB/OGRefNameDB") #  Oil/Gas Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  OGCode::Vector{String} = ReadDisk(db, "MainDB/OGCode")
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGCode")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DEESw::VariableArray{5} = ReadDisk(db,"$Input/DEESw") # [Enduse,Tech,EC,Area,Year] Switch for Device Efficiency (Switch)
  DevROIRef::VariableArray{2} = ReadDisk(OGRefNameDB,"SpOutput/DevROI") # [OGUnit,Year] Development Return on Investment ($/$)
  DevSw::VariableArray{2} = ReadDisk(db,"SpInput/DevSw") # [OGUnit,Year] Development Switch
  OGArea::Array{String} = ReadDisk(db,"SpInput/OGArea") # [OGUnit] Area
  OGECC::Array{String} = ReadDisk(db,"SpInput/OGECC") # [OGUnit] Economic Sector 
  PdROIRef::VariableArray{2} = ReadDisk(OGRefNameDB,"SpOutput/PdROI") # [OGUnit,Year] Reference Case Production Return on Investment ($/$)
  PdSw::VariableArray{2} = ReadDisk(db,"SpInput/PdSw") # [OGUnit,Year] Production Switch
  PEESw::VariableArray{5} = ReadDisk(db,"$Input/PEESw") # [Enduse,Tech,EC,Area,Year] Switch for Process Efficiency (Switch)

end

function OGSetSelect(data,ogunit)
  (;Area,EC,ECC) = data
  (;OGArea,OGECC) = data
  
  area=0
  ec=0
  ecc=0
  OGUnitIsValid="False"
  
  if (OGArea[ogunit] != "")
    area  = Select(Area,OGArea[ogunit])
    ecc   = Select(ECC,OGECC[ogunit])
    ec    = Select(EC,OGECC[ogunit])
   
    if !isempty(area) && !isempty(ec) && !isempty(ecc) 
      OGUnitIsValid="True"
    end   
  end
  
  return area,ec,ecc,OGUnitIsValid
end

function OGRSetSets(data)

end

function TrapROI(db)
  data = IControl(; db)
  (;Input) = data
  (;Enduses) = data
  (;EC,Area,Year) = data
  (;OGUnit,OGUnits,Techs) = data
  (;DEESw,DevROIRef,DevSw,OGCode,PdROIRef,PdSw,PEESw) = data

  years = collect(Future:Final)
  for ogunit in OGUnits
    area,ec,ecc,OGUnitIsValid = OGSetSelect(data,ogunit)
    if OGUnitIsValid == "True"
      for year in years
      
        if DevROIRef[ogunit,year] <= 0.001
          @info "DevROIRef - Switches (DEESw, PEESw) = 6 for $(EC[ec]) $(Area[area]) $(Year[year])"        
          DevSw[ogunit,year]=0
          for tech in Techs, enduse in Enduses
            DEESw[enduse,tech,ec,area,year]=6
            PEESw[enduse,tech,ec,area,year]=6
          end
        end

        if PdROIRef[ogunit,year] <= 0.001
          @info "PdROIRef - Switches (DEESw, PEESw) = 6 for $ec $area $year" 
          PdSw[ogunit,year]=0
          for tech in Techs, enduse in Enduses
            DEESw[enduse,tech,ec,area,year]=6
            PEESw[enduse,tech,ec,area,year]=6
          end    
        end
      end
    end
    OGRSetSets(data)
  end
  #
  # OilSandsMining and OilSandsUpgraders are exceptions
  #
  # Select Nation(CN), Area*
  # Select Area If ANMap eq 1
  # Select EC(OilSandsMining,OilSandsUpgraders)
  # DEESw=6
  # PEESw=6
  # Select ECC*, Area*, Year*
  #
  # TODOPromula: "NL_HeavyOil_0001" was supposed to be on this list, but wasn't 
  # included when executed in Promula - PNV 25 June 2025
  ogunits = Select(OGUnit, ["AB_HeavyOil_0001", "AB_OS_Mining_0001", 
  "AB_OS_CSS_0001", "BC_ConvGas_0001"])
  for ogunit in ogunits
    DevSw[ogunit,Yr(2021)]=0
  end

  WriteDisk(db,"$Input/DEESw",DEESw)
  WriteDisk(db,"SpInput/DevSw",DevSw)
  WriteDisk(db,"SpInput/PdSw",PdSw)
  WriteDisk(db,"$Input/PEESw",PEESw)

end

function Control(db)
  @info "OG_ROITrap.jl - Control"
  TrapROI(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
