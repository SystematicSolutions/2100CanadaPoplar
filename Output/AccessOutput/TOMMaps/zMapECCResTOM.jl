#
# zMapECCResTOM.jl
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

Base.@kwdef struct zMapECCResTOMData
  db::String

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCResTOM::SetArray = ReadDisk(db,"KInput/ECCResTOMKey")
  ECCResTOMDS::SetArray = ReadDisk(db,"KInput/ECCResTOMDS")
  ECCResTOMs::Vector{Int} = collect(Select(ECCResTOM))

  MapECCResTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCResTOM") # [ECC,ECCResTOM] Map between ECCResTOM and ECC
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
end

function zMapECCResTOM_DtaRun(data)
  (; ECC,ECCs,ECCResTOM,ECCResTOMs) = data
  (; MapECCResTOM) = data

  iob = IOBuffer()

  println(iob,"Variable,ECCResTOM,ECC,Data")
  for ecc in ECCs
    for eccrestom in ECCResTOMs
      if MapECCResTOM[ecc,eccrestom] == 1
        println(iob,"MapECCResTOM,",ECCResTOM[eccrestom],",",ECC[ecc],",",@sprintf("%.0f",MapECCResTOM[ecc,eccrestom]))
      end
    end
  end
  
  filename = "zMapECCResTOM.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zMapECCResTOM_DtaControl(db)
  data = zMapECCResTOMData(; db)

  @info "zMapECCResTOM_DtaControl"

  zMapECCResTOM_DtaRun(data)
end

