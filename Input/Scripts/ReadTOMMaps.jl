#
# ReadTOMMaps.jl
#
using EnergyModel

module ReadTOMMaps

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: DB, ModelPath

using CSV, DataFrames, DataFramesMeta

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MapTOMData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  CNAreaTOM::SetArray = ReadDisk(db,"KInput/CNAreaTOMKey")
  CNAreaTOMs::Vector{Int} = collect(Select(CNAreaTOM))
  ECTrans::SetArray = ReadDisk(db,"MainDB/ECTransKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCFloorspaceTOM::SetArray = ReadDisk(db,"KInput/ECCFloorspaceTOMKey")
  ECCFloorspaceTOMs::Vector{Int} = collect(Select(ECCFloorspaceTOM))
  ECCResTOM::SetArray = ReadDisk(db,"KInput/ECCResTOMKey")
  ECCResTOMs::Vector{Int} = collect(Select(ECCResTOM))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESs::Vector{Int} = collect(Select(ES))
  Fleet::SetArray = ReadDisk(db,"KInput/FleetKey")
  Fleets::Vector{Int} = collect(Select(Fleet))
  FuelAggTOM::SetArray = ReadDisk(db,"KInput/FuelAggTOMKey")
  FuelAggTOMs::Vector{Int} = collect(Select(FuelAggTOM))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  PriceTOM::SetArray = ReadDisk(db,"KInput/PriceTOMKey")
  PriceTOMs::Vector{Int} = collect(Select(PriceTOM))
  Process::SetArray = ReadDisk(db, "MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db, "MainDB/ProcessDS")
  Processes::Vector{Int} = collect(Select(Process))
  TechTrans::SetArray = ReadDisk(db,"MainDB/TechTransKey")
  VehicleTOM::SetArray = ReadDisk(db,"KInput/VehicleTOMKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM")   # [Area,AreaTOM]  Map between Area and AreaTOM
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  MapCNAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapCNAreaTOM") # [Area,CNAreaTOM] Map between Area and CNAreaTOM
  MapECCFloorspaceTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCFloorspaceTOM")     # [ECC,ECCFloorspaceTOM] Map between ECCFloorspaceTOM and ECC
  MapECCResTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCResTOM") # [ECC,ECCResTOM] Map between ECCResTOM and ECC
  MapECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCtoTOM") # [ECC,ECCTOM] Map between ECC to ECCTOM
  MapFuelAggTOM::VariableArray{2} = ReadDisk(db,"KInput/MapFuelAggTOM") # [Fuel,FuelAggTOM] Map between Fuel and FuelAggTOM
  MapFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/MapFuelTOM") # [Fuel,FuelTOM] Map between Fuel and FuelTOM
  MapFuelTechECToVehicleFuelTOM::VariableArray{5} = ReadDisk(db,"KInput/MapFuelTechECToVehicleFuelTOM") # [:Fuel,TechTrans,ECTrans,FuelTOM,VehicleTOM] Map between Fuel,Tech and FuelTOM
  MapfromECCTOM::VariableArray{2} = ReadDisk(db,"KInput/MapfromECCTOM") # [ECC,ECCTOM] Map from ECCTOM to ECC
  MapOGProductionTOM::VariableArray{2} = ReadDisk(db,"KInput/MapOGProductionTOM") #[Process,FuelAggTOM] Map of Oil Gas Processes to FuelAggTOM
  MapPriceTOM::VariableArray{3} = ReadDisk(db,"KInput/MapPriceTOM") #[Fuel,ES,PriceTOM] Map from ES and Fuel to PriceTOM
  MapTechToFleet::VariableArray{2} = ReadDisk(db, "KInput/MapTechToFleet") # [Tech,Fleet] Map from Transportation Techs to Fleet
  MapUSECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapUSECCtoTOM") # [ECC,ECCTOM] Map between ECC to ECCTOM
  MapUSfromECCTOM::VariableArray{2} = ReadDisk(db,"KInput/MapUSfromECCTOM") # [ECC,ECCTOM] Map from ECCTOM to ECC

end

function Read2DTOMMaps(db)
  data = MapTOMData(; db);
  (; Area,Nation,AreaTOM,AreaTOMs) = data;
  (; CNAreaTOM,CNAreaTOMs,ECC,ECCs) = data;
  (; ECCFloorspaceTOM,ECCFloorspaceTOMs) = data;
  (; ECCResTOM,ECCResTOMs,ECCTOM,ECCTOMs,Fleet,FuelAggTOMs,FuelAggTOM,Fuel,Fuels) = data;
  (; FuelTOM,FuelTOMs,Process,TechTrans) = data;
  (; MapAreaTOM,MapAreaTOMNation,MapCNAreaTOM) = data;
  (; MapECCFloorspaceTOM,MapfromECCTOM,MapECCtoTOM) = data;
  (; MapECCResTOM,MapUSfromECCTOM,MapUSECCtoTOM) = data;
  (; MapTechToFleet) = data;
  (; MapFuelTOM,MapFuelAggTOM,MapFuelTechECToVehicleFuelTOM) = data;
  (; MapOGProductionTOM) = data;
  
  sets = Dict(
    "Area" => Area,
    "AreaTOM" => AreaTOM,
    "CNAreaTOM" => CNAreaTOM,
    "Nation" => Nation,
    "ECC" => ECC,
    "ECCFloorspaceTOM" => ECCFloorspaceTOM,
    "ECCResTOM" => ECCResTOM,
    "ECCTOM" => ECCTOM,
    "Fleet" => Fleet,
    "Fuel" => Fuel,
    "FuelAggTOM" => FuelAggTOM,
    "FuelTOM" => FuelTOM,
    "Process" => Process,
    "TechTrans" => TechTrans
  )
    
  dataframe_to_array = function(df,arr)
    #
    # Turns dataframe into variable array (set up for arrays of 2-dimensions only). 
    # Assumes dataframe fields are in reverse order as sets. 7/30/25 R.Levesque
    #
    exclude_fields = in.(names(df), Ref(["Variable", "Data"]))
    df_sets = names(df)[.!exclude_fields]
    arr .= 0
    for row in eachrow(df)
      index_last = Select(sets[df_sets[1]], row[df_sets[1]])
      index_first = Select(sets[df_sets[2]], row[df_sets[2]])
      arr[index_first, index_last] = row.Data
    end
    return(arr)
  end
  
  path = joinpath(ModelPath,"Input","TOMMaps")
  
  df_MapAreaTOM = CSV.read(joinpath(path,"MapAreaTOM.csv"), DataFrame;stringtype=String)
  MapAreaTOM = dataframe_to_array(df_MapAreaTOM, MapAreaTOM)
  WriteDisk(db, "KInput/MapAreaTOM", MapAreaTOM)
  
  df_MapAreaTOMNation = CSV.read(joinpath(path,"MapAreaTOMNation.csv"), DataFrame;stringtype=String)
  MapAreaTOMNation = dataframe_to_array(df_MapAreaTOMNation, MapAreaTOMNation)
  WriteDisk(db, "KInput/MapAreaTOMNation", MapAreaTOMNation)

  df_MapCNAreaTOM = CSV.read(joinpath(path,"MapCNAreaTOM.csv"), DataFrame;stringtype=String)
  MapCNAreaTOM = dataframe_to_array(df_MapCNAreaTOM, MapCNAreaTOM)
  WriteDisk(db, "KInput/MapCNAreaTOM", MapCNAreaTOM)

  df_MapECCFloorspaceTOM = CSV.read(joinpath(path,"MapECCFloorspaceTOM.csv"), DataFrame;stringtype=String)
  MapECCFloorspaceTOM = dataframe_to_array(df_MapECCFloorspaceTOM, MapECCFloorspaceTOM)
  WriteDisk(db, "KInput/MapECCFloorspaceTOM", MapECCFloorspaceTOM)
  
  df_MapfromECCTOM = CSV.read(joinpath(path,"MapfromECCTOM.csv"), DataFrame;stringtype=String)
  MapfromECCTOM = dataframe_to_array(df_MapfromECCTOM, MapfromECCTOM)
  WriteDisk(db, "KInput/MapfromECCTOM", MapfromECCTOM)

  df_MapECCtoTOM = CSV.read(joinpath(path,"MapECCtoTOM.csv"), DataFrame;stringtype=String)
  MapECCtoTOM = dataframe_to_array(df_MapECCtoTOM, MapECCtoTOM)
  WriteDisk(db, "KInput/MapECCtoTOM", MapECCtoTOM)

  df_MapECCResTOM = CSV.read(joinpath(path,"MapECCResTOM.csv"), DataFrame;stringtype=String)
  MapECCResTOM = dataframe_to_array(df_MapECCResTOM, MapECCResTOM)
  WriteDisk(db, "KInput/MapECCResTOM", MapECCResTOM)

  df_MapFuelAggTOM = CSV.read(joinpath(path,"MapFuelAggTOM.csv"), DataFrame;stringtype=String)
  MapFuelAggTOM = dataframe_to_array(df_MapFuelAggTOM, MapFuelAggTOM)
  WriteDisk(db, "KInput/MapFuelAggTOM", MapFuelAggTOM)
  
  df_MapFuelTOM = CSV.read(joinpath(path,"MapFuelTOM.csv"), DataFrame;stringtype=String)
  MapFuelTOM = dataframe_to_array(df_MapFuelTOM, MapFuelTOM)
  WriteDisk(db, "KInput/MapFuelTOM", MapFuelTOM)
  
  df_MapOGProductionTOM = CSV.read(joinpath(path,"MapOGProductionTOM.csv"), DataFrame;stringtype=String)
  MapOGProductionTOM = dataframe_to_array(df_MapOGProductionTOM, MapOGProductionTOM)
  WriteDisk(db, "KInput/MapOGProductionTOM", MapOGProductionTOM)
  
  df_MapTechToFleet = CSV.read(joinpath(path,"MapTechToFleet.csv"), DataFrame;stringtype=String)
  MapTechToFleet = dataframe_to_array(df_MapTechToFleet, MapTechToFleet)
  WriteDisk(db, "KInput/MapTechToFleet", MapTechToFleet)
  
  df_MapUSfromECCTOM = CSV.read(joinpath(path,"MapUSfromECCTOM.csv"), DataFrame;stringtype=String)
  MapUSfromECCTOM = dataframe_to_array(df_MapUSfromECCTOM, MapUSfromECCTOM)
  WriteDisk(db, "KInput/MapUSfromECCTOM", MapUSfromECCTOM)
  
  df_MapUSECCtoTOM = CSV.read(joinpath(path,"MapUSECCtoTOM.csv"), DataFrame;stringtype=String)
  MapUSECCtoTOM = dataframe_to_array(df_MapUSECCtoTOM, MapUSECCtoTOM)
  WriteDisk(db, "KInput/MapUSECCtoTOM", MapUSECCtoTOM)

end

function Read3DTOMMaps(db)
  data = MapTOMData(; db);
  (; ES,ESs,Fuel,Fuels,PriceTOM,PriceTOMs) = data;
  (; MapPriceTOM) = data;
  
  sets = Dict(
    "Fuel" => Fuel,
    "ES" => ES,
    "PriceTOM" => PriceTOM
   )
    
  dataframe_to_array = function(df,arr)
    #
    # Turns 5 dimensional dataframe into variable array. 
    # Assumes dataframe fields are in reverse order as sets. 7/30/25 R.Levesque
    #
    exclude_fields = in.(names(df), Ref(["Variable", "Data"]))
    df_sets = names(df)[.!exclude_fields]
    arr .= 0
    for row in eachrow(df)
      index_first = Select(sets[df_sets[3]], row[df_sets[3]])
      index_second = Select(sets[df_sets[2]], row[df_sets[2]])
      index_last = Select(sets[df_sets[1]], row[df_sets[1]])
      arr[index_first,index_second,index_last] = row.Data
    end
    return(arr)
  end
  
  path = joinpath(ModelPath,"Input","TOMMaps")
  
  df_MapPriceTOM = CSV.read(joinpath(path,"MapPriceTOM.csv"), DataFrame;stringtype=String)
  MapPriceTOM = dataframe_to_array(df_MapPriceTOM, MapPriceTOM)
  WriteDisk(db, "KInput/MapPriceTOM", MapPriceTOM)
end

function Read5DTOMMaps(db)
  data = MapTOMData(; db);
  (; ECTrans,Fuel,Fuels,FuelTOM,TechTrans,VehicleTOM) = data;
  (; MapFuelTechECToVehicleFuelTOM) = data;
  
  sets = Dict(
    "ECTrans" => ECTrans,
    "Fuel" => Fuel,
    "FuelTOM" => FuelTOM,
    "TechTrans" => TechTrans,
    "VehicleTOM" => VehicleTOM
   )
    
  dataframe_to_array = function(df,arr)
    #
    # Turns 5 dimensional dataframe into variable array. 
    # Assumes dataframe fields are in reverse order as sets. 7/30/25 R.Levesque
    #
    exclude_fields = in.(names(df), Ref(["Variable", "Data"]))
    df_sets = names(df)[.!exclude_fields]
    arr .= 0
    for row in eachrow(df)
      index_first = Select(sets[df_sets[5]], row[df_sets[5]])
      index_second = Select(sets[df_sets[4]], row[df_sets[4]])
      index_third = Select(sets[df_sets[3]], row[df_sets[3]])
      index_fourth = Select(sets[df_sets[2]], row[df_sets[2]])
      index_last = Select(sets[df_sets[1]], row[df_sets[1]])
      arr[index_first,index_second,index_third,index_fourth,index_last] = row.Data
    end
    return(arr)
  end
  
  path = joinpath(ModelPath,"Input","TOMMaps")
  
  df_MapFuelTechECToVehicleFuelTOM = CSV.read(joinpath(path,"MapFuelTechECToVehicleFuelTOM.csv"), DataFrame;stringtype=String)
  MapAreaTOM = dataframe_to_array(df_MapFuelTechECToVehicleFuelTOM, MapFuelTechECToVehicleFuelTOM)
  WriteDisk(db, "KInput/MapFuelTechECToVehicleFuelTOM", MapFuelTechECToVehicleFuelTOM)
end

function MapControl(db)
  @info "ReadTOMMaps.jl"
  Read2DTOMMaps(db)
  Read3DTOMMaps(db)
  Read5DTOMMaps(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  MapControl(DB)
end

end
