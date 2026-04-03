#
# Waste_Data.jl
#
using EnergyModel

module Waste_Data

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Waste::SetArray = ReadDisk(db,"MainDB/WasteKey")
  WasteDS::SetArray = ReadDisk(db,"MainDB/WasteDS")
  Wastes::Vector{Int} = collect(Select(Waste))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CH4CorrectionFactor::VariableArray{3} = ReadDisk(db,"MInput/CH4CorrectionFactor") # [Waste,Area,Year] CH4 Correction Factor <MCF> for Aerobic Decomposition (Tonnes/Tonnes)
  CH4FlaringFraction::VariableArray{3} = ReadDisk(db,"MInput/CH4FlaringFraction") # [Waste,Area,Year] CH4 Flaring Fraction (Tonnes/Tonnes)
  CH4GenerationRate::VariableArray{3} = ReadDisk(db,"MInput/CH4GenerationRate") # [Waste,Area,Year] CH4 Generation Constant <k>
  CH4MolarRatio::Float32 = ReadDisk(db,"MInput/CH4MolarRatio")[1] # [tv] Molar Ratio CH4 / C  (1/1)
  CH4RecoveryFraction::VariableArray{3} = ReadDisk(db,"MInput/CH4RecoveryFraction") # [Waste,Area,Year] CH4 Recovery Fraction (Tonnes/Tonnes)
  CH4Volume::VariableArray{1} = ReadDisk(db,"MInput/CH4Volume") # [Waste] Fraction of CH4 by Volume in Landfill Gas <F> (Tonnes/Tonnes)
  DisposedSwitch::VariableArray{3} = ReadDisk(db,"MInput/DisposedSwitch") # [Waste,Area,Year] Disposed Waste Policy Switch (1=Active)
  DisposedWastePerDriver::VariableArray{3} = ReadDisk(db,"MInput/DisposedWastePerDriver") # [Waste,Area,Year] Disposed Waste per Driver <DsWC> (Tonnes/Person)
  DivertedPolicyFraction::VariableArray{3} = ReadDisk(db,"MInput/DivertedPolicyFraction") # [Waste,Area,Year] Fraction of Disposed Waste Policy which is Diverted (Tonne/Tonne)
  DOCDecomposeFraction::VariableArray{3} = ReadDisk(db,"MInput/DOCDecomposeFraction") # [Waste,Area,Year] Fraction of Decomposable DOC <DOCf> (Tonnes/Tonnes)
  DOCPerWaste::VariableArray{3} = ReadDisk(db,"MInput/DOCPerWaste") # [Waste,Area,Year] Fraction of Degradable Organic Carbon per Waste Landfilled (Tonnes/Tonnes)
  FlaringEfficiency::VariableArray{3} = ReadDisk(db,"MInput/FlaringEfficiency") # [Waste,Area,Year] Emissions Efficiency of Flaring (Tonnes/Tonnes)
  OxidationFactor::VariableArray{3} = ReadDisk(db,"MInput/OxidationFactor") # [Waste,Area,Year] Oxidation Factor <OX> (Tonnes/Tonnes)
  ProportionDivertedWaste::VariableArray{3} = ReadDisk(db,"MInput/ProportionDivertedWaste") # [Waste,Area,Year] Proportion of Diverted Waste <PDvW> (Tonnes/Tonnes)
  WasteDriverMap::Array{String} = ReadDisk(db,"MOutput/WasteDriverMap") # [Waste] Map for Waste Generation Driver
  WasteExportedFraction::VariableArray{3} = ReadDisk(db,"MInput/WasteExportedFraction") # [Waste,Area,Year] Fraction of Waste Exported (Tonnes/Tonnes)
  WasteIncineratedFraction::VariableArray{3} = ReadDisk(db,"MInput/WasteIncineratedFraction") # [Waste,Area,Year] Fraction of Waste Incinerated (Tonnes/Tonnes)
  WastePerDriver::VariableArray{3} = ReadDisk(db,"MInput/WastePerDriver") # [Waste,Area,Year] Waste Generated per Driver <WGC> (Tonnes/person)
  WasteSwitch::VariableArray{1} = ReadDisk(db,"MInput/WasteSwitch") # [Year] Waste Switch (1=Use Waste Sector)
  xCH4Emitted::VariableArray{3} = ReadDisk(db,"MInput/xCH4Emitted") # [Waste,Area,Year] Exogenous CH4 Generated After Recovery <Qt>  (Tonnes/Yr)
  xPopT::VariableArray{2} = ReadDisk(db,"MInput/xPopT") # [Area,Year] Population (Millions)
  xDOCStock::VariableArray{3} = ReadDisk(db,"MInput/xDOCStock") # [Waste,Area,Year] Input Landfill Stock of Decomposable DOC <DDOCma> (Tonnes)
end

function MCalibration(db)
  data = MControl(; db)
  (;Area,AreaDS,Areas,Waste,WasteDS,Wastes,Year,YearDS,Years) = data
  (;WasteDriverMap,CH4CorrectionFactor,CH4FlaringFraction,CH4GenerationRate,CH4MolarRatio) = data
  (;CH4RecoveryFraction,CH4Volume,DOCDecomposeFraction,DOCPerWaste,FlaringEfficiency) = data
  (;OxidationFactor,ProportionDivertedWaste,WasteExportedFraction,WasteIncineratedFraction) = data
  (;WastePerDriver,WasteSwitch,xCH4Emitted,xPopT,xDOCStock,DisposedSwitch) = data
  (;DisposedWastePerDriver,DivertedPolicyFraction) = data

  # TODOJulia  Scalar Issues? - Luke 11.1.24

  CH4MolarRatio = 4/3
  CH4Volume .= 0.5
  FlaringEfficiency .= 0.997
  OxidationFactor .= 0.1
  WasteSwitch .= 0
  for year in Yr(2024):Final
    WasteSwitch[year] = 1
  end

  # 
  # Disposed Waste Policy
  # 
  DisposedSwitch .= 0
  DisposedWastePerDriver .= 0
  DivertedPolicyFraction .= 0.6
    
  # 
  # Default Waste drive is for Municipal Waste (Population)
  #
  WasteDriverMap .= "Population"
  WasteDriverMap[Select(Waste,"WoodWastePulpPaper")] = "PulpPaperMills"
  # *Select Waste(WoodWasteSolidWood)
  # *Select ECC(Forestry)

  # 
  # Below are assumptions/conversions from the 'MSW_E2020.xlsx' spreadsheet model
  # that are not included in VBInput data - Ian 02/16/18
  #
  CH4CorrectionFactor .= 1.0
  # wastes = Select(Waste,["WoodWastePulpPaper","WoodWasteSolidWood"])
  for area in Areas, year in Years
    for waste in Wastes
      CH4FlaringFraction[waste,area,year] = CH4FlaringFraction[waste,area,Yr(2024)]
      CH4GenerationRate[waste,area,year] = CH4GenerationRate[waste,area,Yr(2023)]
      CH4RecoveryFraction[waste,area,year] = CH4RecoveryFraction[waste,area,Yr(2024)]
      DOCDecomposeFraction[waste,area,year] = DOCDecomposeFraction[waste,area,Yr(2024)]
      DOCPerWaste[waste,area,year] = DOCPerWaste[waste,area,Yr(2024)]
      ProportionDivertedWaste[waste,area,year] = ProportionDivertedWaste[waste,area,Yr(2023)]
      WasteExportedFraction[waste,area,year] = WasteExportedFraction[waste,area,Yr(2023)]
      WasteIncineratedFraction[waste,area,year] = WasteIncineratedFraction[waste,area,Yr(2023)]
      WastePerDriver[waste,area,year] = WastePerDriver[waste,area,Yr(2023)]
    end
    for waste in Select(Waste,["WoodWastePulpPaper","WoodWasteSolidWood"])
      CH4CorrectionFactor[waste,area,year] = 0.8

      # 
      # MSW values are in vData, so just enter Wood Waste values here
      # 
      CH4GenerationRate[waste,area,year] = 0.03
    end
    DOCPerWaste[Select(Waste,"WoodWasteSolidWood"),area,year] = 0.43
    DOCPerWaste[Select(Waste,"WoodWastePulpPaper"),area,year] = 0.46
  end

  areas = Select(Area,(from = "ON", to = "NU"))
  oud = Select(Waste,"OtherUnknownDry")
  xCH4Emitted[oud,Select(AreaDS,"Ontario"),             Yr(2024)] = 0
  xCH4Emitted[oud,Select(AreaDS,"Quebec"),              Yr(2024)] = 0
  xCH4Emitted[oud,Select(AreaDS,"British Columbia"),    Yr(2024)] = 0
  xCH4Emitted[oud,Select(AreaDS,"Alberta"),             Yr(2024)] = 0
  xCH4Emitted[oud,Select(AreaDS,"Manitoba"),            Yr(2024)] = 0
  xCH4Emitted[oud,Select(AreaDS,"Saskatchewan"),        Yr(2024)] = 0
  xCH4Emitted[oud,Select(AreaDS,"New Brunswick"),       Yr(2024)] = 0
  xCH4Emitted[oud,Select(AreaDS,"Nova Scotia"),         Yr(2024)] = 0
  xCH4Emitted[oud,Select(AreaDS,"Newfoundland"),        Yr(2024)] = 0
  xCH4Emitted[oud,Select(AreaDS,"Prince Edward Island"),Yr(2024)] = 0
  xCH4Emitted[oud,Select(AreaDS,"Yukon Territory"),     Yr(2024)] = 0
  xCH4Emitted[oud,Select(AreaDS,"Northwest Territory"), Yr(2024)] = 0
  xCH4Emitted[oud,Select(AreaDS,"Nunavut"),             Yr(2024)] = 0
  for area in areas, year in Yr(2025):Final
    @finite_math xCH4Emitted[oud,area,year] = xCH4Emitted[oud,area,year-1]*xPopT[area,year]/xPopT[area,year-1]
  end

  # 
  # xDOCStock has a single year of data in current version. Hold constant
  # historically and set to -99 in the forecast.
  # 
  for waste in Wastes, area in Areas
    for year in 1:Yr(2022)
      xDOCStock[waste,area,year] = xDOCStock[waste,area,Yr(2023)]
    end
    for year in Yr(2024):Final
      xDOCStock[waste,area,year] = -99
    end
  end

  WriteDisk(db,"MOutput/WasteDriverMap",WasteDriverMap)
  WriteDisk(db,"MInput/CH4CorrectionFactor",CH4CorrectionFactor)
  WriteDisk(db,"MInput/CH4FlaringFraction",CH4FlaringFraction)
  WriteDisk(db,"MInput/CH4GenerationRate",CH4GenerationRate)
  WriteDisk(db,"MInput/CH4MolarRatio",CH4MolarRatio)
  WriteDisk(db,"MInput/CH4RecoveryFraction",CH4RecoveryFraction)
  WriteDisk(db,"MInput/CH4Volume",CH4Volume)
  WriteDisk(db,"MInput/DOCDecomposeFraction",DOCDecomposeFraction)
  WriteDisk(db,"MInput/DOCPerWaste",DOCPerWaste)
  WriteDisk(db,"MInput/FlaringEfficiency",FlaringEfficiency)
  WriteDisk(db,"MInput/OxidationFactor",OxidationFactor)
  WriteDisk(db,"MInput/ProportionDivertedWaste",ProportionDivertedWaste)
  WriteDisk(db,"MInput/WasteExportedFraction",WasteExportedFraction)
  WriteDisk(db,"MInput/WasteIncineratedFraction",WasteIncineratedFraction)
  WriteDisk(db,"MInput/WastePerDriver",WastePerDriver)
  WriteDisk(db,"MInput/WasteSwitch",WasteSwitch)
  WriteDisk(db,"MInput/xCH4Emitted",xCH4Emitted)
  WriteDisk(db,"MInput/xDOCStock",xDOCStock)
  WriteDisk(db,"MInput/DisposedSwitch",DisposedSwitch)
  WriteDisk(db,"MInput/DisposedWastePerDriver",DisposedWastePerDriver)
  WriteDisk(db,"MInput/DivertedPolicyFraction",DivertedPolicyFraction)

end

function CalibrationControl(db)
  @info "Waste_Data.jl - CalibrationControl"

  MCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
