#
# RPP_ProductionImportsExports_VB.jl - Assign Oil Refinery vData input variables to model variables
#
using EnergyModel

module RPP_ProductionImportsExports_VB

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
  Crude::SetArray = ReadDisk(db,"MainDB/CrudeKey")
  CrudeDS::SetArray = ReadDisk(db,"MainDB/CrudeDS")
  Crudes::Vector{Int} = collect(Select(Crude))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  RfUnit::SetArray = ReadDisk(db,"MainDB/RfUnitKey")
  RfUnits::Vector{Int} = collect(Select(RfUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  RfArea::Array{String} = ReadDisk(db,"SpInput/RfArea") # [RfUnit] Refinery Area
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vRfCap::VariableArray{2} = ReadDisk(db,"VBInput/vRfCap") # [RfUnit,Year] Refining Unit Capacity (TBtu/Yr)
  vRfProd::VariableArray{3} = ReadDisk(db,"VBInput/vRfProd") # [RfUnit,Fuel,Year] Refining Unit Production (TBtu/Yr)
  vRPPAProd::VariableArray{2} = ReadDisk(db,"VBInput/vRPPAProd") # [vArea,Year] Refinery Production (TBtu/Yr)
  vRPPCrude::VariableArray{3} = ReadDisk(db,"VBInput/vRPPCrude") # [Crude,vArea,Year] Crude Oil Refined (TBtu/Yr)
  vRPPExports::VariableArray{2} = ReadDisk(db,"VBInput/vRPPExports") # [Nation,Year] Refined Petroleum Products (RPP) Exports (TBtu/Yr)
  vRPPExportsArea::VariableArray{3} = ReadDisk(db,"VBInput/vRPPExportsArea") # [Fuel,Area,Year] RPP Exports (TBtu/Yr)  
  vRPPExportsNation::VariableArray{3} = ReadDisk(db,"VBInput/vRPPExportsNation") # [Fuel,Nation,Year] RPP Exports (TBtu/Yr)
  vRPPExportsROW::VariableArray{3} = ReadDisk(db,"VBInput/vRPPExportsROW") # [Fuel,Area,Year] RPP Exports to ROW (TBtu/Yr)
  vRPPImports::VariableArray{2} = ReadDisk(db,"VBInput/vRPPImports") # [Nation,Year] Refined Petroleum Products (RPP) Imports (TBtu/Yr)
  vRPPImportsArea::VariableArray{3} = ReadDisk(db,"VBInput/vRPPImportsArea") # [Fuel,Area,Year] RPP Imports (TBtu/Yr) 
  vRPPImportsNation::VariableArray{3} = ReadDisk(db,"VBInput/vRPPImportsNation") # [Fuel,Nation,Year] RPP Imports (TBtu/Yr) 
  vRPPImportsROW::VariableArray{3} = ReadDisk(db,"VBInput/vRPPImportsROW") # [Fuel,Area,Year] RPP Imports from ROW (TBtu/Yr)
  vRPPProd::VariableArray{2} = ReadDisk(db,"VBInput/vRPPProd") # [Nation,Year] Refined Petroleum Products Production (TBtu/Yr)
  xRfCap::VariableArray{2} = ReadDisk(db,"SpInput/xRfCap") # [RfUnit,Year] Refining Unit Capacity (TBtu/Yr)
  xRfProd::VariableArray{3} = ReadDisk(db,"SpInput/xRfProd") # [RfUnit,Fuel,Year] Refining Unit Production (TBtu/Yr)
  xRPPAProd::VariableArray{2} = ReadDisk(db,"SInput/xRPPAProd") # [Area,Year] Refinery Production (TBtu/Yr)
  xRPPCrude::VariableArray{3} = ReadDisk(db,"SpInput/xRPPCrude") # [Crude,Area,Year] Crude Oil Refined (TBtu/Yr)
  xRPPExports::VariableArray{2} = ReadDisk(db,"SpInput/xRPPExports") # [Nation,Year] RPP Exports (TBtu/Yr)
  xRPPExportsArea::VariableArray{3} = ReadDisk(db,"SpInput/xRPPExportsArea") # [Fuel,Area,Year] RPP Exports (TBtu/Yr)  
  xRPPExportsNation::VariableArray{3} = ReadDisk(db,"SpInput/xRPPExportsNation") # [Fuel,Nation,Year] RPP Exports (TBtu/Yr)
  xRPPExportsROW::VariableArray{3} = ReadDisk(db,"SpInput/xRPPExportsROW") # [Fuel,Area,Year] RPP Exports to ROW (TBtu/Yr)
  xRPPImports::VariableArray{2} = ReadDisk(db,"SpInput/xRPPImports") # [Nation,Year] RPP Imports (TBtu/Yr)
  xRPPImportsArea::VariableArray{3} = ReadDisk(db,"SpInput/xRPPImportsArea") # [Fuel,Area,Year] RPP Imports (TBtu/Yr) 
  xRPPImportsNation::VariableArray{3} = ReadDisk(db,"SpInput/xRPPImportsNation") # [Fuel,Nation,Year] RPP Imports (TBtu/Yr)
  xRPPImportsROW::VariableArray{3} = ReadDisk(db,"SpInput/xRPPImportsROW") # [Fuel,Area,Year] RPP Imports from ROW (TBtu/Yr)
  xRPPProd::VariableArray{2} = ReadDisk(db,"SInput/xRPPProd") # [Nation,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)
  xRPPProdArea::VariableArray{3} = ReadDisk(db,"SpInput/xRPPProdArea") # [Fuel,Area,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)
  xRPPProdNation::VariableArray{3} = ReadDisk(db,"SpInput/xRPPProdNation") # [Fuel,Nation,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)

  AreaFraction::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year]

  NationProd::VariableArray{1} = zeros(Float32,length(Year)) 
end

function SCalibration(db)
  data = SControl(; db)
  (;Area,AreaDS,Areas,Crude,CrudeDS,Crudes,Fuel,FuelDS,Fuels,Nation) = data
  (;NationDS,Nations,RfUnit,RfUnits,Year,YearDS,Years,vArea,vAreaDS,vAreas) = data
  (;ANMap,AreaFraction,NationProd,RfArea,vAreaMap,vRfCap,vRfProd,vRPPAProd,vRPPCrude,vRPPExports,vRPPExportsArea,vRPPExportsNation,vRPPExportsROW) = data
  (;vRPPImports,vRPPImportsArea,vRPPImportsNation,vRPPImportsROW,vRPPProd,xRfCap,xRfProd,xRPPAProd) = data
  (;xRPPCrude,xRPPExports,xRPPExportsArea,xRPPExportsNation,xRPPExportsROW,xRPPImports,xRPPImportsArea,xRPPImportsNation,xRPPImportsROW,xRPPProd) = data
  (;xRPPProdArea,xRPPProdNation) = data

  #
  # ********************
  #
  # 1. Read in data from AMD, totals not by fuel thru 2050: vRPPAProd, vRPPExports, vRPPImports
  # 2. Read in data from SSI, totals not fy fuel thru 2050: vRPPProd, vRPPExports, vRPPImports
  # 3. Read in data from SSI by Fuel: vRfProd, vRfCap, vRPPImportsArea, vRPPImportsNation, 
  #                                   vRPPImportsROW, vRPPExportsArea, vRPPExportsNation, vRPPExportsROW
  # 4. From Randy:  Should we scale xRfProd to RPP totals (vRPPAProd, vRPPProd) so they match? 10/24/24
  # 5. Assign xRfProd to xRPPProdArea and xRPPProdNation
  #
  # RPP production totals not by fuel thru 2050 (vRPPAProd, vRPPProd, vRPPExports, vRPPImports)
  #
  CN=Select(Nation,"CN")
  areas = findall(ANMap[Areas,CN] .== 1)
  for year in Years, area in areas
    xRPPAProd[area,year] = 
      sum(vRPPAProd[varea,year]*vAreaMap[area,varea] for varea in vAreas)
  end
  for year in Years
    xRPPProd[CN,year] = sum(xRPPAProd[area,year] for area in areas)
  end
  
  US=Select(Nation,"US")
  WSC=Select(Area,"WSC")
  MX=Select(Nation,"MX")
  MXa=Select(Area,"MX")
  for year in Years
    xRPPProd[US,year] = vRPPProd[US,year]
    xRPPAProd[WSC,year] = xRPPProd[US,year]

    xRPPProd[MX,year] = vRPPProd[MX,year]
    xRPPAProd[MXa,year] = xRPPProd[MX,year]
  end

  WriteDisk(db,"SInput/xRPPAProd", xRPPAProd)
  WriteDisk(db,"SInput/xRPPProd", xRPPProd)

  #
  # RPP imports and exports not by fuel thru 2050
  #
  @. xRPPImports = vRPPImports
  @. xRPPExports = vRPPExports

  WriteDisk(db,"SpInput/xRPPImports", xRPPImports)
  WriteDisk(db,"SpInput/xRPPExports", xRPPExports)

  #
  # Older data (review and update .dat files)
  #
  for year in Years, crude in Crudes, area in Areas
    xRPPCrude[crude,area,year] = 
      sum(vRPPCrude[crude,varea,year]*vAreaMap[area,varea] for varea in vAreas)
  end
  WriteDisk(db,"SpInput/xRPPCrude", xRPPCrude)


  @. xRPPExportsArea = vRPPExportsArea
  @. xRPPExportsNation = vRPPExportsNation
  @. xRPPExportsROW = vRPPExportsROW
  WriteDisk(db,"SpInput/xRPPExportsArea", xRPPExportsArea)
  WriteDisk(db,"SpInput/xRPPExportsNation", xRPPExportsNation)
  WriteDisk(db,"SpInput/xRPPExportsROW", xRPPExportsROW)

  @. xRPPImportsArea = vRPPImportsArea
  @. xRPPImportsNation = vRPPImportsNation
  @. xRPPImportsROW = vRPPImportsROW
  WriteDisk(db,"SpInput/xRPPImportsArea", xRPPImportsArea)
  WriteDisk(db,"SpInput/xRPPImportsNation", xRPPImportsNation)
  WriteDisk(db,"SpInput/xRPPImportsROW", xRPPImportsROW)

  #
  # ********************
  #
  # Production by refinery units
  #
  @. xRfCap = vRfCap
  @. xRfProd = vRfProd
  WriteDisk(db,"SpInput/xRfProd", xRfProd)
  WriteDisk(db,"SpInput/xRfCap", xRfCap)

  for year in Years, area in Areas
    rfunits = findall(RfArea[RfUnits] .== Area[area])
    if !isempty(rfunits)
      for fuel in Fuels
        xRPPProdArea[fuel,area,year] = 
           sum(xRfProd[rfunit,fuel,year] for rfunit in rfunits)
      end
    end
  end
  WriteDisk(db,"SpInput/xRPPProdArea", xRPPProdArea)

  for nation in Nations
    areas = findall(ANMap[Areas,nation] .== 1)
    if !isempty(areas)
      for year in Years, fuel in Fuels    
        xRPPProdNation[fuel,nation,year] = 
          sum(xRPPProdArea[fuel,area,year] for area in areas)
      end
    end
  end
  WriteDisk(db,"SpInput/xRPPProdNation", xRPPProdNation)
  
  #
  # Redistribute US RPP production in xRPPAProd across areas based on xRPPProdArea areas.
  #
  nation = Select(Nation,"US")
  areas = findall(ANMap[Areas,nation] .== 1)
  
  for year in Years
    NationProd[year] = sum(xRPPAProd[area,year] for area in areas)
  end
  
  for year in Years, area in areas  
    AreaFraction[area,year] =
      sum(xRPPProdArea[fuel,area,year] for fuel in Fuels)/
      sum(xRPPProdArea[fuel,area,year] for fuel in Fuels, area in Areas)
  end   

  for year in Years, area in areas  
    xRPPAProd[area,year] = NationProd[year]*AreaFraction[area,year]
  end
  
  for year in Years
    xRPPProd[nation,year] = sum(xRPPAProd[area,year] for area in areas)
  end 
    
  WriteDisk(db,"SInput/xRPPAProd",xRPPAProd)
  WriteDisk(db,"SInput/xRPPProd",xRPPProd)    

end

function Control(db)
  @info "RPP_ProductionImportsExports_VB.jl - Control"
  SCalibration(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
