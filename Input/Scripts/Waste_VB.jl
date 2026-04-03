#
# Waste_VB.jl - Assigns Waste input data from vData.accdb to model variables
#
########################
#  MODEL VARIABLE             VDATA VARIABLE
#   xDOCStock =                vDDOCm_accum
#   ProportionDivertedWaste =  vDiversionRate
#   DOCPerWaste =              vDOC
#   WastePerDriver =           vGenerated_Driver
#   WasteIncineratedFraction = vIncinerated
#   CH4GenerationRate =        vk
#   WasteExportedFraction)=    vXport
#   CH4RecoveryFraction =      vCapture_Rate
#   CH4FlaringFraction =       vFlaring_Rate
########################
# 
using EnergyModel

module Waste_VB

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
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))

  CH4FlaringFraction::VariableArray{3} = ReadDisk(db,"MInput/CH4FlaringFraction") # [Waste,Area,Year] CH4 Flaring Fraction (Tonnes/Tonnes)
  CH4GenerationRate::VariableArray{3} = ReadDisk(db,"MInput/CH4GenerationRate") # [Waste,Area,Year] CH4 Generation Constant <k>
  CH4RecoveryFraction::VariableArray{3} = ReadDisk(db,"MInput/CH4RecoveryFraction") # [Waste,Area,Year] CH4 Recovery Fraction (Tonnes/Tonnes)
  DOCDecomposeFraction::VariableArray{3} = ReadDisk(db,"MInput/DOCDecomposeFraction") # [Waste,Area,Year] Fraction of Decomposable DOC <DOCf> (Tonnes/Tonnes)
  DOCPerWaste::VariableArray{3} = ReadDisk(db,"MInput/DOCPerWaste") # [Waste,Area,Year] Fraction of Degradable Organic Carbon per Waste Landfilled (Tonnes/Tonnes)
  ProportionDivertedWaste::VariableArray{3} = ReadDisk(db,"MInput/ProportionDivertedWaste") # [Waste,Area,Year] Proportion of Diverted Waste <PDvW> (Tonnes/Tonnes)
  vCapture_Rate::VariableArray{3} = ReadDisk(db,"VBInput/vCapture_Rate") # [Waste,vArea,Year] CH4 Recovery Fraction (Tonnes/Tonnes)
  vDDOCm_accum::VariableArray{3} = ReadDisk(db,"VBInput/vDDOCm_accum") # [Waste,vArea,Year] Initial DDOC Accumulation (Tonnes)
  vDiversionRate::VariableArray{3} = ReadDisk(db,"VBInput/vDiversionRate") # [Waste,vArea,Year] Proportion of Diverted Waste <PDvW> (Tonnes/Tonnes)
  vDOC::VariableArray{3} = ReadDisk(db,"VBInput/vDOC") # [Waste,vArea,Year] Fraction of Degradable Organic Carbon per Waste Landfilled (Tonnes/Tonnes)
  vDOCDecomposeFraction::VariableArray{3} = ReadDisk(db,"VBInput/vDOCDecomposeFraction") # [Waste,vArea,Year] Fraction of Decomposable DOC <DOCf> (Tonnes/Tonnes)
  vFlaring_Rate::VariableArray{3} = ReadDisk(db,"VBInput/vFlaring_Rate") # [Waste,vArea,Year] CH4 Flaring Fraction (Tonnes/Tonnes)
  vGenerated_Driver::VariableArray{3} = ReadDisk(db,"VBInput/vGenerated_Driver") # [Waste,vArea,Year] Waste per Driver <WGC> (Tonnes/Person)
  vIncinerated::VariableArray{3} = ReadDisk(db,"VBInput/vIncinerated") # [Waste,vArea,Year] Fraction of Waste Incinerated (Tonnes/Tonnes)
  vk::VariableArray{3} = ReadDisk(db,"VBInput/vk") # [Waste,vArea,Year] CH4 Generation Constant <k>
  vXport::VariableArray{3} = ReadDisk(db,"VBInput/vXport") # [Waste,vArea,Year] Fraction of Waste Exported (Tonnes/Tonnes)
  WasteExportedFraction::VariableArray{3} = ReadDisk(db,"MInput/WasteExportedFraction") # [Waste,Area,Year] Fraction of Waste Exported (Tonnes/Tonnes)
  WasteIncineratedFraction::VariableArray{3} = ReadDisk(db,"MInput/WasteIncineratedFraction") # [Waste,Area,Year] Fraction of Waste Incinerated (Tonnes/Tonnes)
  WastePerDriver::VariableArray{3} = ReadDisk(db,"MInput/WastePerDriver") # [Waste,Area,Year] Waste Generated per Driver <WGC> (Tonnes/Person)
  xDOCStock::VariableArray{3} = ReadDisk(db,"MInput/xDOCStock") # [Waste,Area,Year] Input Landfill Stock of Decomposable DOC <DDOCma> (Tonnes)
end

function WasteVB(db)
  data = MControl(; db)
  (;Area,Wastes,Years,vArea,vAreas) = data
  (;CH4FlaringFraction,CH4GenerationRate,CH4RecoveryFraction) = data
  (;DOCDecomposeFraction,DOCPerWaste,ProportionDivertedWaste) = data
  (;vCapture_Rate,vDDOCm_accum,vDiversionRate,vDOC,vDOCDecomposeFraction) = data
  (;vFlaring_Rate,vGenerated_Driver,vIncinerated,vk,vXport) = data
  (;WastePerDriver,WasteExportedFraction,WasteIncineratedFraction) = data
  (;xDOCStock,) = data

  for year in Years, varea in vAreas, waste in Wastes 
    area = Select(Area,vArea[varea])
    
    xDOCStock[waste,area,year] = vDDOCm_accum[waste,varea,year]
 
    ProportionDivertedWaste[waste,area,year] = vDiversionRate[waste,varea,year]
 
    DOCPerWaste[waste,area,year] = vDOC[waste,varea,year]
    
    DOCDecomposeFraction[waste,area,year] = vDOCDecomposeFraction[waste,varea,year]
    
    WastePerDriver[waste,area,year] = vGenerated_Driver[waste,varea,year]
    
    WasteIncineratedFraction[waste,area,year] = vIncinerated[waste,varea,year]
    
    CH4GenerationRate[waste,area,year] = vk[waste,varea,year]
    
    WasteExportedFraction[waste,area,year] = vXport[waste,varea,year]
    
    CH4RecoveryFraction[waste,area,year] = vCapture_Rate[waste,varea,year]
    
    CH4FlaringFraction[waste,area,year] = vFlaring_Rate[waste,varea,year]
    
  end

  WriteDisk(db,"MInput/CH4FlaringFraction",CH4FlaringFraction)
  WriteDisk(db,"MInput/CH4GenerationRate",CH4GenerationRate)
  WriteDisk(db,"MInput/CH4RecoveryFraction",CH4RecoveryFraction)
  WriteDisk(db,"MInput/DOCDecomposeFraction",DOCDecomposeFraction)
  WriteDisk(db,"MInput/DOCPerWaste",DOCPerWaste)
  WriteDisk(db,"MInput/ProportionDivertedWaste",ProportionDivertedWaste)
  WriteDisk(db,"MInput/WasteExportedFraction",WasteExportedFraction)
  WriteDisk(db,"MInput/WasteIncineratedFraction",WasteIncineratedFraction)
  WriteDisk(db,"MInput/WastePerDriver",WastePerDriver)
  WriteDisk(db,"MInput/xDOCStock",xDOCStock)

end

function Control(db)
  @info "Waste_VB.jl - Control"
  WasteVB(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
