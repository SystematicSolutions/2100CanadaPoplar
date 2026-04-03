#
# EconomicDrivers_VB.jl - Macroeconomic variables from VBInput
#
using EnergyModel

module EconomicDrivers_VB

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
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))

  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  FSUnit::VariableArray{3} = ReadDisk(db,"MInput/FSUnit") # [ECC,Area,Year] Floorspace per Unit (Sq Ft/Building)
  vFSUnit::VariableArray{3} = ReadDisk(db,"VBInput/vFSUnit") # [ECC,vArea,Year] Floorspace per Unit (Million Sq Ft/Building)
  xECUF::VariableArray{3} = ReadDisk(db,"MInput/xECUF") # [ECC,Area,Year] Capital Utilization Fraction ($/$)
  xHSize::VariableArray{3} = ReadDisk(db,"MInput/xHSize") # [ECC,Area,Year] Household Size (People/Household)
  MWDecayTime::VariableArray{1} = ReadDisk(db,"MEInput/MWDecayTime") # [Area] Municipal Waste Decay Time (Years)
  PCPL::VariableArray{3} = ReadDisk(db,"MInput/PCPL") # [ECC,Area,Year] Physical Life of Production Capacity (YearS)
  vECUF::VariableArray{3} = ReadDisk(db,"VBInput/vECUF") # [ECC,Area,Year] Capital Utilization Fraction ($/$)
  vHSize::VariableArray{3} = ReadDisk(db,"VBInput/vHSize") # [ECC,Area,Year] Household Size (People/Household)
  vMWDecayTime::VariableArray{1} = ReadDisk(db,"VBInput/vMWDecayTime") # [Area] Municipal Waste Decay Time (Years)
  vPCPL::VariableArray{3} = ReadDisk(db,"VBInput/vPCPL") # [ECC,Area,Year] Physical Life of Production Capacity (Years)
  xGO::VariableArray{3} = ReadDisk(db,"MInput/xGO") # [ECC,Area,Year] Gross Output (Real $M/Yr)
  xGRP::VariableArray{2} = ReadDisk(db,"MInput/xGRP") # [Area,Year] Gross Regional Product (Real $M/Yr)
  xPopT::VariableArray{2} = ReadDisk(db,"MInput/xPopT") # [Area,Year] Population (Millions)
  xRPI::VariableArray{2} = ReadDisk(db,"MInput/xRPI") # [Area,Year] Personal Income (Real $M/Yr)
  vGO::VariableArray{3} = ReadDisk(db,"VBInput/vGO") # [ECC,Area,Year] Gross Output (Real 1985 M$/Yr)
  vGRP::VariableArray{2} = ReadDisk(db,"VBInput/vGRP") # [Area,Year] Gross Regional Product (Real 1985 M$/Yr)
  vPopT::VariableArray{2} = ReadDisk(db,"VBInput/vPopT") # [Area,Year] Population (Millions)
  vRPI::VariableArray{2} = ReadDisk(db,"VBInput/vRPI") # [Area,Year] Total Personal Income (Real 1985 M$/Yr)
  xFloorspaceAEO::VariableArray{3} = ReadDisk(db,"MInput/xFloorspaceAEO") # [ECC,Area,Year] Floor Space from AEO (Million Sq Ft)
  xGOAEO::VariableArray{3} = ReadDisk(db,"MInput/xGOAEO") # [ECC,Area,Year] Gross Output from AEO (Real M$/Yr)
  xGRPAEO::VariableArray{2} = ReadDisk(db,"MInput/xGRPAEO") # [Area,Year] US Gross Regional Product from AEO (Real M$/Yr)
  xHHSAEO::VariableArray{3} = ReadDisk(db,"MInput/xHHSAEO") # [ECC,Area,Year] Households from AEO (Households)
  xPopAEO::VariableArray{3} = ReadDisk(db,"MInput/xPopAEO") # [ECC,Area,Year] Population by Household Type (Millions)
  xPopTAEO::VariableArray{2} = ReadDisk(db,"MInput/xPopTAEO") # [Area,Year] Population (Millions)
  xRPIAEO::VariableArray{2} = ReadDisk(db,"MInput/xRPIAEO") # [Area,Year] Total Personal Income (Real M$/Yr)
  vFloorspaceAEO::VariableArray{3} = ReadDisk(db,"VBInput/vFloorspaceAEO") # [ECC,Area,Year] Floorspace from AEO (Million Sq Ft)
  vGOAEO::VariableArray{3} = ReadDisk(db,"VBInput/vGOAEO") # [ECC,Area,Year] Gross Output from AEO (2012 M$/Yr)
  vGRPAEO::VariableArray{2} = ReadDisk(db,"VBInput/vGRPAEO") # [Area,Year] US Gross Regional Product from AEO (Real M$/Yr)
  vHHSAEO::VariableArray{3} = ReadDisk(db,"VBInput/vHHSAEO") # [ECC,Area,Year] Households from AEO (Households)
  vPopAEO::VariableArray{3} = ReadDisk(db,"VBInput/vPopAEO") # [ECC,Area,Year] Population by Household Type (Millions)
  vPopTAEO::VariableArray{2} = ReadDisk(db,"VBInput/vPopTAEO") # [Area,Year] Population (Millions)
  vRPIAEO::VariableArray{2} = ReadDisk(db,"VBInput/vRPIAEO") # [Area,Year] Total Personal Income (Real M$/Yr)

  VehicleSalesRatio::VariableArray{4} = ReadDisk(db,"KInput/VehicleSalesRatio") # [Fleet,ECCTOM,AreaTOM,Year] Transportation Investments as Fraction of Gross Output (Btu/Btu)
  vVehicleSalesRatio::VariableArray{4} = ReadDisk(db,"VBInput/vVehicleSalesRatio") # [Fleet,ECCTOM,AreaTOM,Year] Transportation Investments as Fraction of Gross Output (Btu/Btu)

end

function MCalibration(db)
  data = MControl(; db)
  (;Area,ECCs,Nation) = data
  (;Years,vAreas) = data
  (;ANMap,FSUnit,vFSUnit,xECUF,xHSize,MWDecayTime,PCPL,vECUF,vHSize,vMWDecayTime) = data
  (;vPCPL,xGO,xGRP,xPopT,xRPI,vGO,vGRP,vPopT,vRPI,xFloorspaceAEO) = data
  (;xGOAEO,xGRPAEO,xHHSAEO,xPopAEO,xPopTAEO,xRPIAEO) = data
  (;VehicleSalesRatio,vFloorspaceAEO,vGOAEO,vGRPAEO,vHHSAEO) = data
  (;vPopAEO,vPopTAEO,vRPIAEO,vAreaMap) = data
  (;vVehicleSalesRatio) = data

  # 
  # Floorspace per Unit
  # 
  CN = Select(Nation, "CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)

  # 
  # Map FSUnit from vArea 
  # 
  for ecc in ECCs, area in cn_areas, year in Years
    FSUnit[ecc,area,year]  = sum(vFSUnit[ecc,v,year]*vAreaMap[area,v] for v in vAreas)
  end

  for ecc in ECCs, area in cn_areas, year in Yr(2036):Yr(2050)
    FSUnit[ecc,area,year]  = FSUnit[ecc,area,Yr(2035)]
  end

  xECUF .= vECUF
  xHSize .= vHSize
  MWDecayTime .= vMWDecayTime
  PCPL .= vPCPL

  # 
  # Economic Variables for Mexico come from VBInput
  # 
  MX = Select(Area,"MX")
  xGO[ECCs,MX,Years] .= vGO[ECCs,MX,Years]
  xGRP[MX,Years] .= vGRP[MX,Years]
  xPopT[MX,Years] .= vPopT[MX,Years]
  xRPI[MX,Years] .= vRPI[MX,Years]
    
  # 
  # Economic Variables from Annual Energy Outlook (xGOAEO)
  # 
  xFloorspaceAEO .= vFloorspaceAEO
  xGOAEO .= vGOAEO
  xGRPAEO .= vGRPAEO
  xHHSAEO .= vHHSAEO
  xPopAEO .= vPopAEO
  xPopTAEO .= vPopTAEO
  xRPIAEO .= vRPIAEO

  #
  # Vehicle Sales Ratios used to Calculate Transportation Portion of Investments for TOM
  #
  VehicleSalesRatio .= vVehicleSalesRatio

  WriteDisk(db,"MInput/FSUnit",FSUnit)
  WriteDisk(db,"MInput/xECUF",xECUF)
  WriteDisk(db,"MInput/xHSize",xHSize)
  WriteDisk(db,"MEInput/MWDecayTime",MWDecayTime)
  WriteDisk(db,"MInput/PCPL",PCPL)

  WriteDisk(db,"MInput/xGO",xGO)
  WriteDisk(db,"MInput/xGRP",xGRP)
  WriteDisk(db,"MInput/xPopT",xPopT)
  WriteDisk(db,"MInput/xRPI",xRPI)

  WriteDisk(db,"MInput/xFloorspaceAEO",xFloorspaceAEO)
  WriteDisk(db,"MInput/xGOAEO",xGOAEO)
  WriteDisk(db,"MInput/xGRPAEO",xGRPAEO)
  WriteDisk(db,"MInput/xHHSAEO",xHHSAEO)
  WriteDisk(db,"MInput/xPopAEO",xPopAEO)
  WriteDisk(db,"MInput/xPopTAEO",xPopTAEO)
  WriteDisk(db,"MInput/xRPIAEO",xRPIAEO)
  WriteDisk(db,"KInput/VehicleSalesRatio",VehicleSalesRatio)

end

function CalibrationControl(db)
  @info "EconomicDrivers_VB.jl - CalibrationControl"

  MCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
