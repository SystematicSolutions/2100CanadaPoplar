#
# NGTransmission_VB.jl
#
using EnergyModel

module NGTransmission_VB

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
  GNode::SetArray = ReadDisk(db,"MainDB/GNodeKey")
  GNodeDS::SetArray = ReadDisk(db,"MainDB/GNodeDS")
  GNodeX::SetArray = ReadDisk(db,"MainDB/GNodeXKey")
  GNodeXDS::SetArray = ReadDisk(db,"MainDB/GNodeXDS")
  GNodeXs::Vector{Int} = collect(Select(GNodeX))
  GNodes::Vector{Int} = collect(Select(GNode))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  GAvFrLNG::VariableArray{3} = ReadDisk(db,"SpInput/GAvFrLNG") # [GNode,Month,Year] Fraction of the LNG Capacity Available for Dispatch
  GAvFrProd::VariableArray{3} = ReadDisk(db,"SpInput/GAvFrProd") # [GNode,Month,Year] Fraction of NG Production Available Each Month
  GAvFrStorage::VariableArray{3} = ReadDisk(db,"SpInput/GAvFrStorage") # [GNode,Month,Year] Fraction of NG Storage Available Each Month 
  GFillFrStorage::VariableArray{3} = ReadDisk(db,"SpInput/GFillFrStorage") # [GNode,Month,Year] Fraction of Storage Capacity Filled (Btu/Btu)
  GLSF::VariableArray{3} = ReadDisk(db,"SpInput/GLSF") # [Month,Area,Year] Natural Gas Load Shape Factor (Btu/Btu)
  GNodeAreaMap::VariableArray{2} = ReadDisk(db,"SpInput/GNodeAreaMap") # [GNode,Area] Natural Gas Node to Area Map
  GNodeNationMap::VariableArray{2} = ReadDisk(db,"SpInput/GNodeNationMap") # [GNode,Nation] Natural Gas Node to Nation Map
  GNodeXAreaMap::VariableArray{2} = ReadDisk(db,"SpInput/GNodeXAreaMap") # [GNodeX,Area] Natural Gas Node to Area Map
  GNodeXNationMap::VariableArray{2} = ReadDisk(db,"SpInput/GNodeXNationMap") # [GNodeX,Nation] Natural Gas Node to Nation Map
  GTrEff::VariableArray{4} = ReadDisk(db,"SpInput/GTrEff") # [GNode,GNodeX,Month,Year] Natural Gas Transmission Efficiency (TBtu/TBtu)
  GTrMax::VariableArray{4} = ReadDisk(db,"SpInput/GTrMax") # [GNode,GNodeX,Month,Year] Natural Gas Transmission Capacity (TBtu/Month) 
  GUVCStorage::VariableArray{3} = ReadDisk(db,"SpInput/GUVCStorage") # [GNode,Month,Year] Unit Non-Fuel Variable Cost from Storage (Local$/mmBtu)
  xGCapLNGExports::VariableArray{3} = ReadDisk(db,"SpInput/xGCapLNGExports") # [GNode,Month,Year] Exogenous LNG Exports Capacity (TBtu/Yr)
  xGCapLNGImports::VariableArray{3} = ReadDisk(db,"SpInput/xGCapLNGImports") # [GNode,Month,Year] Exogenous LNG Imports Capacity (TBtu/Yr)
  xGCapStorage::VariableArray{3} = ReadDisk(db,"SpInput/xGCapStorage") # [GNode,Month,Year] Exogenous Storage Capacity (TBtu/Yr)
  xGExpDChg::VariableArray{3} = ReadDisk(db,"SpInput/xGExpDChg") # [GNode,Month,Year] World Natural Gas Price Differential (Local$/mmBtu) 
  xGLvStorage::VariableArray{3} = ReadDisk(db,"SpInput/xGLvStorage") # [GNode,Month,Year] Historical Level of Natural Gas in Storage (TBtu) 
  xGTrFlow::VariableArray{4} = ReadDisk(db,"SpInput/xGTrFlow") # [GNode,GNodeX,Month,Year] Natural Gas Transmission Flow (TBtu/Month)
  xGTrVC::VariableArray{4} = ReadDisk(db,"SpInput/xGTrVC") # [GNode,GNodeX,Month,Year] Natural Gas Transmission Variable Cost (US$/mmBtu)
  xGVCLNG::VariableArray{3} = ReadDisk(db,"SpInput/xGVCLNG") # [GNode,Month,Year] Historical Natural Gas Variable Cost from LNG (Local$/mmBtu) 
  xGVCProd::VariableArray{3} = ReadDisk(db,"SpInput/xGVCProd") # [GNode,Month,Year] Historical Natural Gas Variable Cost from Production (Local$/mmBtu) 
  vGAvFrLNG::VariableArray{3} = ReadDisk(db,"VBInput/vGAvFrLNG") # [GNode,Month,Year] Fraction of the LNG Capacity Available for Dispatch
  vGAvFrProd::VariableArray{3} = ReadDisk(db,"VBInput/vGAvFrProd") # [GNode,Month,Year] Fraction of NG Production Available Each Month
  vGAvFrStorage::VariableArray{3} = ReadDisk(db,"VBInput/vGAvFrStorage") # [GNode,Month,Year] Fraction of NG Storage Available Each Month 
  vGCapLNGExports::VariableArray{3} = ReadDisk(db,"VBInput/vGCapLNGExports") # [GNode,Month,Year] Exogenous LNG Exports Capacity (TBtu/Yr)
  vGCapLNGImports::VariableArray{3} = ReadDisk(db,"VBInput/vGCapLNGImports") # [GNode,Month,Year] Exogenous LNG Imports Capacity (TBtu/Yr)
  vGCapStorage::VariableArray{3} = ReadDisk(db,"VBInput/vGCapStorage") # [GNode,Month,Year] Exogenous Storage Capacity (TBtu/Yr)
  vGExpDChg::VariableArray{3} = ReadDisk(db,"VBInput/vGExpDChg") # [GNode,Month,Year] World Natural Gas Price Differential (Local$/mmBtu) 
  vGFillFrStorage::VariableArray{3} = ReadDisk(db,"VBInput/vGFillFrStorage") # [GNode,Month,Year] Fraction of Storage Capacity Filled (Btu/Btu)
  vGLSF::VariableArray{3} = ReadDisk(db,"VBInput/vGLSF") # [Month,Area,Year] Natural Gas Load Shape Factor (Btu/Btu)
  vGLvStorage::VariableArray{3} = ReadDisk(db,"VBInput/vGLvStorage") # [GNode,Month,Year] Historical Level of Natural Gas in Storage (TBtu) 
  vGNodeAreaMap::VariableArray{2} = ReadDisk(db,"VBInput/vGNodeAreaMap") # [GNode,Area] Natural Gas Node to Area Map
  vGNodeNationMap::VariableArray{2} = ReadDisk(db,"VBInput/vGNodeNationMap") # [GNode,Nation] Natural Gas Node to Nation Map
  vGNodeXAreaMap::VariableArray{2} = ReadDisk(db,"VBInput/vGNodeXAreaMap") # [GNodeX,Area] Natural Gas Node to Area Map
  vGNodeXNationMap::VariableArray{2} = ReadDisk(db,"VBInput/vGNodeXNationMap") # [GNodeX,Nation] Natural Gas Node to Nation Map
  vGTrEff::VariableArray{4} = ReadDisk(db,"VBInput/vGTrEff") # [GNode,GNodeX,Month,Year] Natural Gas Transmission Efficiency (TBtu/TBtu)
  vGTrFlow::VariableArray{4} = ReadDisk(db,"VBInput/vGTrFlow") # [GNode,GNodeX,Month,Year] Natural Gas Transmission Flow (TBtu/Month)
  vGTrMax::VariableArray{4} = ReadDisk(db,"VBInput/vGTrMax") # [GNode,GNodeX,Month,Year] Natural Gas Transmission Capacity (TBtu/Month) 
  vGTrVC::VariableArray{4} = ReadDisk(db,"VBInput/vGTrVC") # [GNode,GNodeX,Month,Year] Natural Gas Transmission Variable Cost (US$/mmBtu)
  vGUVCStorage::VariableArray{3} = ReadDisk(db,"VBInput/vGUVCStorage") # [GNode,Month,Year] Unit Non-Fuel Variable Cost from Storage (Local$/mmBtu)
  vGVCLNG::VariableArray{3} = ReadDisk(db,"VBInput/vGVCLNG") # [GNode,Month,Year] Historical Natural Gas Variable Cost from LNG (Local$/mmBtu) 
  vGVCProd::VariableArray{3} = ReadDisk(db,"VBInput/vGVCProd") # [GNode,Month,Year] Historical Natural Gas Variable Cost from Production (Local$/mmBtu) 

  # Scratch Variables
end

function SCalibration(db)
  data = SControl(; db)
  (;GAvFrLNG,GAvFrProd,GAvFrStorage,GFillFrStorage,GLSF,GNodeAreaMap,GNodeNationMap) = data
  (;GNodeXAreaMap,GNodeXNationMap,GTrEff,GTrMax,GUVCStorage,xGCapLNGExports,xGCapLNGImports) = data
  (;xGCapStorage,xGExpDChg,xGLvStorage,xGTrFlow,xGTrVC,xGVCLNG,xGVCProd,vGAvFrLNG) = data
  (;vGAvFrProd,vGAvFrStorage,vGCapLNGExports,vGCapLNGImports,vGCapStorage,vGExpDChg) = data
  (;vGFillFrStorage,vGLSF,vGLvStorage,vGNodeAreaMap,vGNodeNationMap,vGNodeXAreaMap) = data
  (;vGNodeXNationMap,vGTrEff,vGTrFlow,vGTrMax,vGTrVC,vGUVCStorage,vGVCLNG,vGVCProd) = data

   @. GAvFrLNG = vGAvFrLNG
   WriteDisk(db,"SpInput/GAvFrLNG",GAvFrLNG)

   @. GAvFrProd = vGAvFrProd
   WriteDisk(db,"SpInput/GAvFrProd",GAvFrProd)

   @. GAvFrStorage = vGAvFrStorage
   WriteDisk(db,"SpInput/GAvFrStorage",GAvFrStorage)

   @. xGCapLNGExports = vGCapLNGExports
   WriteDisk(db,"SpInput/xGCapLNGExports",xGCapLNGExports)

   @. xGCapLNGImports = vGCapLNGImports
   WriteDisk(db,"SpInput/xGCapLNGImports",xGCapLNGImports)

   @. xGCapStorage = vGCapStorage
   WriteDisk(db,"SpInput/xGCapStorage",xGCapStorage)

   @. GFillFrStorage = vGFillFrStorage
   WriteDisk(db,"SpInput/GFillFrStorage",GFillFrStorage)

   @. GLSF = vGLSF
   WriteDisk(db,"SpInput/GLSF",GLSF)

   @. GNodeAreaMap = vGNodeAreaMap
   @. GNodeXAreaMap = vGNodeXAreaMap
   WriteDisk(db,"SpInput/GNodeAreaMap",GNodeAreaMap)
   WriteDisk(db,"SpInput/GNodeXAreaMap",GNodeXAreaMap)

   @. GNodeNationMap = vGNodeNationMap
   @. GNodeXNationMap = vGNodeXNationMap
   WriteDisk(db,"SpInput/GNodeNationMap",GNodeNationMap)
   WriteDisk(db,"SpInput/GNodeXNationMap",GNodeXNationMap)

   @. GTrEff = vGTrEff
   WriteDisk(db,"SpInput/GTrEff",GTrEff)

   @. GTrMax = vGTrMax
   WriteDisk(db,"SpInput/GTrMax",GTrMax)

   @. GUVCStorage = vGUVCStorage
   WriteDisk(db,"SpInput/GUVCStorage",GUVCStorage)

   @. xGExpDChg = vGExpDChg
   WriteDisk(db,"SpInput/xGExpDChg",xGExpDChg)

   @. xGLvStorage = vGLvStorage
   WriteDisk(db,"SpInput/xGLvStorage",xGLvStorage)

   @. xGTrVC = vGTrVC
   WriteDisk(db,"SpInput/xGTrVC",xGTrVC)

   @. xGTrFlow = vGTrFlow
   WriteDisk(db,"SpInput/xGTrFlow",xGTrFlow)

   @. xGVCLNG = vGVCLNG
   WriteDisk(db,"SpInput/xGVCLNG",xGVCLNG)

   @. xGVCProd = vGVCProd
   WriteDisk(db,"SpInput/xGVCProd",xGVCProd)
   
end

function CalibrationControl(db)
  @info "NGTransmission_VB.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
