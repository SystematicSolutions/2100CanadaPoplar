#
# zMapECCFloorspaceTOM.jl
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

Base.@kwdef struct zMapECCFloorspaceTOMData
  db::String

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCFloorspaceTOM::SetArray = ReadDisk(db,"KInput/ECCFloorspaceTOMKey")
  ECCFloorspaceTOMs::Vector{Int} = collect(Select(ECCFloorspaceTOM))

  MapECCFloorspaceTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCFloorspaceTOM")     # [ECC,ECCFloorspaceTOM] Map between ECCFloorspaceTOM and ECC
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
end

function zMapECCFloorspaceTOM_DtaRun(data)
  (; ECC,ECCs,ECCFloorspaceTOM,ECCFloorspaceTOMs) = data
  (; MapECCFloorspaceTOM) = data

  iob = IOBuffer()

  println(iob,"Variable,ECC,ECCFloorspaceTOM,Data")
  for ecc in ECCs
    for eccfloorspacetom in ECCFloorspaceTOMs
      if MapECCFloorspaceTOM[ecc,eccfloorspacetom] ==1
        println(iob,"MapECCFloorspaceTOM,",ECC[ecc],",",ECCFloorspaceTOM[eccfloorspacetom],",",@sprintf("%.0f",MapECCFloorspaceTOM[ecc,eccfloorspacetom]))
      end
    end
  end
  
  filename = "zMapECCFloorspaceTOM.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zMapECCFloorspaceTOM_DtaControl(db)
  data = zMapECCFloorspaceTOMData(; db)

  @info "zMapECCFloorspaceTOM_DtaControl"

  zMapECCFloorspaceTOM_DtaRun(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
  zMapECCFloorspaceTOM_DtaControl(DB)
end
