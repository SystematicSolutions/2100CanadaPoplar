#
# ReadActiveTOMSetValues.jl
#
using EnergyModel

module ReadActiveTOMSetValues

import ...EnergyModel: ReadDisk, WriteDisk, Select
import ...EnergyModel: DB, ModelPath

using CSV, DataFrames, DataFramesMeta

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ActiveSetValuesData
  db::String

  ECCTOM::SetArray = ReadDisk(db, "KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  FuelTOM::SetArray = ReadDisk(db, "KInput/FuelTOMKey")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  ToTOMVariable::SetArray = ReadDisk(db,"KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))

  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  IsActiveToFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToFuelTOM") # [FuelTOM,ToTOMVariable] "Flag Indicating Which FuelTOMs go into TOM by Variable")
end

#
# Populate active set values for ECCTOM
#
function PopulateIsActiveToECCTOM(db)
  data = ActiveSetValuesData(; db)
  (; ECCTOM,ECCTOMs,ToTOMVariable,ToTOMVariables) = data
  (; IsActiveToECCTOM) = data

  sets = Dict(
    "ECCTOM" => ECCTOM,
    "ToTOMVariable" => ToTOMVariable
  )

  IsActiveToECCTOM .= 0

  path = joinpath(ModelPath, "Input", "IsActiveTOMValues")

  df_IsActiveToECCTOM = CSV.read(joinpath(path,"IsActiveToECCTOM.csv"), DataFrame; stringtype=String)

  #
  # Assign active flags for EIntE, EPermitE, IF_NRG, IF_Tra, IF_OthE, and IFC_PolE
  #
    column_names = names(df_IsActiveToECCTOM)

    DefaultintoTOM = Select(ToTOMVariable,"DefaultintoTOM")
    DefaultfromTOM = Select(ToTOMVariable,"DefaultfromTOM")
    EIntE = Select(ToTOMVariable,"EIntE")
    EPermitE = Select(ToTOMVariable,"EPermitE")
    IF_NRG = Select(ToTOMVariable,"IF_NRG")
    IF_Tra = Select(ToTOMVariable,"IF_Tra")
    IF_OthE = Select(ToTOMVariable,"IF_OthE")
    IFC_PolE = Select(ToTOMVariable,"IFC_PolE")
    OMExpE = Select(ToTOMVariable,"OMExpE")
    
    for row in eachrow(df_IsActiveToECCTOM)
      ecctom = Select(ECCTOM,row.Key)
      if !isempty(ecctom)
        IsActiveToECCTOM[ecctom,DefaultintoTOM] = row.DefaultintoTOM
        IsActiveToECCTOM[ecctom,DefaultfromTOM] = row.DefaultfromTOM
        IsActiveToECCTOM[ecctom,EIntE] = row.EIntE
        IsActiveToECCTOM[ecctom,EPermitE] = row.EPermitE
        IsActiveToECCTOM[ecctom,IF_NRG] = row.IF_NRG
        IsActiveToECCTOM[ecctom,IF_Tra] = row.IF_Tra
        IsActiveToECCTOM[ecctom,IF_OthE] = row.IF_OthE
        IsActiveToECCTOM[ecctom,IFC_PolE] = row.IFC_PolE
        IsActiveToECCTOM[ecctom,OMExpE] = row.OMExpE
      end
    end
    
  WriteDisk(db,"KInput/IsActiveToECCTOM",IsActiveToECCTOM)
end

#
# Populate active set values for FuelTOM
#
function PopulateIsActiveToFuelTOM(db)
  data = ActiveSetValuesData(; db)
  (; FuelTOM,FuelTOMs,ToTOMVariable,ToTOMVariables) = data
  (; IsActiveToFuelTOM) = data

  sets = Dict(
    "FuelTOM" => FuelTOM,
    "ToTOMVariable" => ToTOMVariable
  )  

  IsActiveToFuelTOM .= 0

  path = joinpath(ModelPath,"Input","IsActiveTOMValues")

  df_IsActiveToFuelTOM = CSV.read(joinpath(path,"IsActiveToFuelTOM.csv"),DataFrame; stringtype=String)

  #
  # Assign active flags for EIntE, EIntETr, KMShare_e
  #
    column_names = names(df_IsActiveToFuelTOM)

    EIntE = Select(ToTOMVariable,"EIntE")
    EIntETr = Select(ToTOMVariable,"EIntETr")
    KMShare_e = Select(ToTOMVariable,"KMShare_e")
    
    for row in eachrow(df_IsActiveToFuelTOM)
      fueltom = Select(FuelTOM,row.Key)
      if !isempty(fueltom)
        IsActiveToFuelTOM[fueltom,EIntE] = row.EIntE
        IsActiveToFuelTOM[fueltom,EIntETr] = row.EIntETr
        IsActiveToFuelTOM[fueltom,KMShare_e] = row.KMShare_e
      end
    end
    
  WriteDisk(db,"KInput/IsActiveToFuelTOM",IsActiveToFuelTOM)
end

function Control(db)
  @info "ReadActiveTOMSetValues.jl"
  PopulateIsActiveToECCTOM(db)
  PopulateIsActiveToFuelTOM(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
