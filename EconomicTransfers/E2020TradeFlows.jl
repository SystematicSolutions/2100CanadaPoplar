#
# E2020TradeFlows.jl
#
using EnergyModel

module E2020TradeFlows

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelAggTOM::SetArray = ReadDisk(db,"KInput/FuelAggTOMKey")
  FuelAggTOMDS::SetArray = ReadDisk(db,"KInput/FuelAggTOMDS")
  FuelAggTOMs::Vector{Int} = collect(Select(FuelAggTOM))
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  Inflow::VariableArray{4} = ReadDisk(db,"SpOutput/Inflow") # [Fuel,Area,Nation,Year] Energy Flow to Area from Nation (TBtu/Yr)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  MapFuelAggTOM::VariableArray{2} = ReadDisk(db,"KInput/MapFuelAggTOM") #[Fuel,FuelAggTOM] Map between Fuel and FuelAggTOM
  MNe::VariableArray{3} = ReadDisk(db,"KOutput/MNe") # [FuelAggTOM,AreaTOM,Year] Domestic Imports (TBtu/Yr)
  MXe::VariableArray{3} = ReadDisk(db,"KOutput/MXe") # [FuelAggTOM,AreaTOM,Year] International Imports (TBtu/Yr)
  Outflow::VariableArray{4} = ReadDisk(db,"SpOutput/Outflow") # [Fuel,Area,Nation,Year] Energy Outflow from Area to Nation (TBtu/Yr)
  XN::VariableArray{3} = ReadDisk(db,"KOutput/XN") # [FuelAggTOM,AreaTOM,Year] Domestic Exports (TBtu/Yr)
  XNe::VariableArray{3} = ReadDisk(db,"KOutput/XNe") # [FuelAggTOM,AreaTOM,Year] Domestic Exports (TBtu/Yr)
  XXe::VariableArray{3} = ReadDisk(db,"KOutput/XXe") # [FuelAggTOM,AreaTOM,Year] International Exports (TBtu/Yr)

  # Scratch Variables
end

function InitializeTradeFlows(db)
  data = MControl(;db)
  (;Area,AreaDS,AreaTOM,AreaTOMDS,AreaTOMs,Areas,Fuel,FuelAggTOM,FuelAggTOMDS,FuelAggTOMs) = data
  (;FuelDS,Fuels,Nation,NationDS,Nations,Year,YearDS,Years) = data
  (;ANMap,Inflow,MapAreaTOM,MapFuelAggTOM,MNe,MXe,Outflow,XN,XNe,XXe) = data

  for year in Years, areatom in AreaTOMs, fuelaggtom in FuelAggTOMs
    MNe[fuelaggtom,areatom,year] = 0.0
    XNe[fuelaggtom,areatom,year] = 0.0
    MXe[fuelaggtom,areatom,year] = 0.0
    XXe[fuelaggtom,areatom,year] = 0.0
  end
  
  WriteDisk(db,"KOutput/MNe",MNe)
  WriteDisk(db,"KOutput/XNe",XNe)
  WriteDisk(db,"KOutput/MXe",MXe)
  WriteDisk(db,"KOutput/XXe",XXe)
  
end

function TradeFlows(db)
  data = MControl(;db)
  (;Area,AreaDS,AreaTOM,AreaTOMDS,AreaTOMs,Areas,Fuel,FuelAggTOM,FuelAggTOMDS,FuelAggTOMs) = data
  (;FuelDS,Fuels,Nation,NationDS,Nations,Year,YearDS,Years) = data
  (;ANMap,Inflow,MapAreaTOM,MapAreaTOMNation,MapFuelAggTOM,MNe,MXe,Outflow,XN,XNe,XXe) = data

  TOMArea = Select(AreaTOM,"WSC")
  TOMFuel = Select(FuelAggTOM,"RPP")
  
  #
  # Domestic trade flows within Canada
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[Areas,CN] .== 1)
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1)
    
  for areatom in areatoms, area in areas
    if MapAreaTOM[area,areatom] == 1
      for fuelaggtom in FuelAggTOMs, fuel in Fuels
        if MapFuelAggTOM[fuel,fuelaggtom] == 1 
          for year in Years 
            MNe[fuelaggtom,areatom,year] =
              MNe[fuelaggtom,areatom,year]+Inflow[fuel,area,CN,year]
            
            XNe[fuelaggtom,areatom,year] =
              XNe[fuelaggtom,areatom,year]+Outflow[fuel,area,CN,year]
          end
        end
      end
    end
  end

  #
  # Domestic trade flows within US
  #
  US = Select(Nation,"US")
  areas = findall(ANMap[Areas,US] .== 1)
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1)
  
  #loc1 = XNe[TOMFuel,TOMArea,Yr(2023)]
  #@info " XNe     = $loc1  Start"
  
  
  
  for areatom in areatoms, area in areas
    if MapAreaTOM[area,areatom] == 1
      for fuelaggtom in FuelAggTOMs, fuel in Fuels
        if MapFuelAggTOM[fuel,fuelaggtom] == 1 
          for year in Years 
            MNe[fuelaggtom,areatom,year] = 
              MNe[fuelaggtom,areatom,year]+Inflow[fuel,area,US,year]
            
            XNe[fuelaggtom,areatom,year] =
              XNe[fuelaggtom,areatom,year]+Outflow[fuel,area,US,year]
          end
          
          #loc1 = XNe[TOMFuel,TOMArea,Yr(2023)]
          #@info " XNe     = $loc1  $fuelaggtom, $areatom, $fuel, $area "
          #loc1 = Outflow[fuel,area,US,Yr(2023)]
          #@info " Outflow = $loc1  $fuelaggtom, $areatom, $fuel, $area "          
          
        end
      end
    end
  end

  #
  # International trade flows - Into Canada from Non-Canada; From Canada to Non-Canada
  #
  nations = Select(Nation,!=("CN"))
  areas = findall(ANMap[Areas,CN] .== 1)
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1)
  
  for areatom in areatoms, area in areas
    if MapAreaTOM[area,areatom] == 1
      for fuelaggtom in FuelAggTOMs, fuel in Fuels
        if MapFuelAggTOM[fuel,fuelaggtom] == 1 
          for year in Years, nation in nations
          
            XXe[fuelaggtom,areatom,year] =
              XXe[fuelaggtom,areatom,year]+Outflow[fuel,area,nation,year]
            
            MXe[fuelaggtom,areatom,year] =
              MXe[fuelaggtom,areatom,year]+Inflow[fuel,area,nation,year]                                            
          
          end
        end
      end
    end
  end

  #
  # International trade flows - United States
  #
  nations = Select(Nation,!=("US"))
  areas = findall(ANMap[Areas,US] .== 1)
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1)
  
  for areatom in areatoms, area in areas
    if MapAreaTOM[area,areatom] == 1
      for fuelaggtom in FuelAggTOMs, fuel in Fuels
        if MapFuelAggTOM[fuel,fuelaggtom] == 1 
          for year in Years, nation in nations   
          
            XXe[fuelaggtom,areatom,year] =
              XXe[fuelaggtom,areatom,year]+Outflow[fuel,area,nation,year]    
          
            MXe[fuelaggtom,areatom,year] =
              MXe[fuelaggtom,areatom,year]+Inflow[fuel,area,nation,year]                      
           
          end
        end
      end
    end
  end

  WriteDisk(db,"KOutput/MNe",MNe)
  WriteDisk(db,"KOutput/XNe",XNe)
  WriteDisk(db,"KOutput/MXe",MXe)
  WriteDisk(db,"KOutput/XXe",XXe)
end

function Control(db)
  @info "E2020TradeFlows.jl - Control"
  InitializeTradeFlows(db)
  TradeFlows(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
