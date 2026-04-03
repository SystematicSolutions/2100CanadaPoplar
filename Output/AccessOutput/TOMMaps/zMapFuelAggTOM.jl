#
# zMapFuelAggTOM.jl
#
using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct zMapFuelAggTOMData
  db::String

  FuelAggTOM::SetArray = ReadDisk(db,"KInput/FuelAggTOMKey")
  FuelAggTOMDS::SetArray = ReadDisk(db,"KInput/FuelAggTOMDS")
  FuelAggTOMs::Vector{Int} = collect(Select(FuelAggTOM))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))

   MapFuelAggTOM::VariableArray{2} = ReadDisk(db,"KInput/MapFuelAggTOM") # [Fuel,FuelAggTOM] Map between Fuel and FuelAggTOM
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
 end

function zMapFuelAggTOM_DtaRun(data)
  (; FuelAggTOM,FuelAggTOMs,Fuel,Fuels) = data
  (; MapFuelAggTOM) = data

  iob = IOBuffer()

  println(iob,"Variable,FuelAggTOM,Fuel,Data")
  for fuel in Fuels
    for fuelaggtom in FuelAggTOMs
      if MapFuelAggTOM[fuel,fuelaggtom] == 1
        println(iob,"MapFuelAggTOM,",FuelAggTOM[fuelaggtom],",",Fuel[fuel],",",@sprintf("%.0f",MapFuelAggTOM[fuel,fuelaggtom]))
      end
    end
  end
  
  filename = "zMapFuelAggTOM.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zMapFuelAggTOM_DtaControl(db)
  data = zMapFuelAggTOMData(; db)

  @info "zMapFuelAggTOM_DtaControl"

  zMapFuelAggTOM_DtaRun(data)
end

