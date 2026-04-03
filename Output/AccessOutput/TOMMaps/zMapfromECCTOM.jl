#
# zMapfromECCTOM.jl
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

Base.@kwdef struct zMapfromECCTOMData
  db::String

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))

  MapfromECCTOM::VariableArray{2} = ReadDisk(db,"KInput/MapfromECCTOM") # [ECC,ECCTOM] Map between ECCTOM and ECC
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
end

function zMapfromECCTOM_DtaRun(data)
  (; ECC,ECCs,ECCTOM,ECCTOMs) = data
  (; MapfromECCTOM) = data

  iob = IOBuffer()

  println(iob,"Variable,ECCTOM,ECC,Data")
  for ecc in ECCs
    for ecctom in ECCTOMs
      if MapfromECCTOM[ecc,ecctom] == 1
        println(iob,"MapfromECCTOM,",ECCTOM[ecctom],",",ECC[ecc],",",@sprintf("%.0f",MapfromECCTOM[ecc,ecctom]))
      end
    end
  end
  
  filename = "zMapfromECCTOM.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zMapfromECCTOM_DtaControl(db)
  data = zMapfromECCTOMData(; db)

  @info "zMapfromECCTOM_DtaControl"

  zMapfromECCTOM_DtaRun(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
  zMapfromECCTOM_DtaControl(DB)
end
