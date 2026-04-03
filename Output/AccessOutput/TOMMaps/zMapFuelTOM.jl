#
# zMapFuelTOM.jl
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

Base.@kwdef struct zMapFuelTOMData
  db::String

  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMDS::SetArray = ReadDisk(db,"KInput/FuelTOMDS")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  
  MapFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/MapFuelTOM") # [Fuel,FuelTOM] Map between Fuel and FuelTOM
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
 end

function zMapFuelTOM_DtaRun(data)
  (; FuelTOM,FuelTOMs,Fuel,Fuels) = data
  (; MapFuelTOM) = data

  iob = IOBuffer()

  println(iob,"Variable,FuelTOM,Fuel,Data")
  for fuel in Fuels
    for fueltom in FuelTOMs
      if MapFuelTOM[fuel,fueltom] == 1
        println(iob,"MapFuelTOM,",FuelTOM[fueltom],",",Fuel[fuel],",",@sprintf("%.0f",MapFuelTOM[fuel,fueltom]))
      end
    end
  end
  
  filename = "zMapFuelTOM.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zMapFuelTOM_DtaControl(db)
  data = zMapFuelTOMData(; db)

  @info "zMapFuelTOM_DtaControl"

  zMapFuelTOM_DtaRun(data)
end

